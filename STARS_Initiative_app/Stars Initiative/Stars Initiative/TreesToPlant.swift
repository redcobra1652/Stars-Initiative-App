//
//  TreesToPlant.swift
//  Tree App
//
//  Camera plot analysis using photo + quad-draw + CoreMotion pitch estimation.
//  No ARKit — works on every iPhone including Simulator (camera disabled in sim).
//
//  CHANGES:
//  • New home screen: browse STARS tree inventory (CR/ES/EV + overall) OR start step-by-step
//  • Step indicator ("Step X of Y") shown next to progress bar throughout the form
//  • Results screen: ordered list of ALL fitting trees, biggest first (size as tiebreaker on
//    equal score), grouped into Top Pick / Moderate / Other; trees scoring < 60 show ⚠️
//  • Scoring logic: score is primary sort key; within equal score, bigger tree wins
//    (requiredGroundArea desc), promoting diversity (large trees whenever space allows)
//

import SwiftUI
import PhotosUI
import AVFoundation
import CoreMotion

// MARK: - Data Models

struct Tree: Identifiable {
    let id = UUID()
    let name: String
    let scientificName: String
    let score: Double
    let priority: Int
    let cr: Int
    let es: Int
    let ev: Int
    let bd: Int
    let pc: Int
    let waterNeeds: String
    let maxHeight: Int         // meters
    let maxSpread: Int         // meters
    let trunkDiameter: Double  // meters (mature DBH estimate)

    var requiredGroundArea: Double {
        9.0 * trunkDiameter * trunkDiameter
    }

    var isLowScore: Bool { score < 60 }
}

struct PlotMeasurement {
    var widthMeters: Double
    var lengthMeters: Double
    var area: Double
    var verticalClearance: Double = 3.0
    var horizontalClearance: Double = 8.0

    var usableSpread: Double {
        min(sqrt(max(area, 0)) * 4, horizontalClearance)
    }
}

// MARK: - Shared Inventory

func loadTreeInventory() -> [Tree] {
    guard let url = Bundle.main.url(forResource: "tree_data", withExtension: "csv"),
          let contents = try? String(contentsOf: url, encoding: .utf8) else {
        return []
    }
    var trees: [Tree] = []
    let lines = contents.components(separatedBy: "\n").dropFirst() // skip header
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }
        // Split on commas but respect quoted fields
        let fields = parseCSVLine(trimmed)
        guard fields.count >= 13 else { continue }
        guard let score         = Double(fields[2]),
              let priority      = Int(fields[3]),
              let cr            = Int(fields[4]),
              let es            = Int(fields[5]),
              let ev            = Int(fields[6]),
              let bd            = Int(fields[7]),
              let pc            = Int(fields[8]),
              let maxHeight     = Int(fields[10]),
              let maxSpread     = Int(fields[11]),
              let trunkDiameter = Double(fields[12]) else { continue }
        trees.append(Tree(
            name:          fields[0],
            scientificName: fields[1],
            score:         score,
            priority:      priority,
            cr:            cr,
            es:            es,
            ev:            ev,
            bd:            bd,
            pc:            pc,
            waterNeeds:    fields[9],
            maxHeight:     maxHeight,
            maxSpread:     maxSpread,
            trunkDiameter: trunkDiameter
        ))
    }
    return trees
}

private func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var current = ""
    var inQuotes = false
    for char in line {
        if char == "\"" {
            inQuotes.toggle()
        } else if char == "," && !inQuotes {
            fields.append(current)
            current = ""
        } else {
            current.append(char)
        }
    }
    fields.append(current)
    return fields
}

let treeInventory: [Tree] = loadTreeInventory()

// MARK: - Camera Capture

#if targetEnvironment(simulator)
struct CameraCapture: View {
    @Binding var capturedImage: UIImage?
    var onDismiss: () -> Void

    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Choose Photo", systemImage: "photo.on.rectangle")
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(Color.green)
                .cornerRadius(14)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    await MainActor.run {
                        capturedImage = img
                        onDismiss()
                    }
                }
            }
        }
    }
}
#else
struct CameraCapture: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.showsCameraControls = true
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapture
        init(_ parent: CameraCapture) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.capturedImage = info[.originalImage] as? UIImage
            parent.onDismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}
#endif

// MARK: - Quad Draw View

struct QuadDrawView: View {
    let image: UIImage
    let pitchDegrees: Double
    @Binding var measurement: PlotMeasurement?
    var onConfirm: () -> Void

    @State private var points: [CGPoint] = []
    @State private var viewSize: CGSize = .zero
    @State private var measured = false
    @State private var assumedHeight: Double = 1.2
    @State private var verticalClearance: Double = 6.0
    @State private var horizontalClearance: Double = 8.0
    @State private var errorMessage: String? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width)

                if points.count >= 2 {
                    Path { path in
                        path.move(to: points[0])
                        points.dropFirst().forEach { path.addLine(to: $0) }
                        if points.count == 4 { path.closeSubpath() }
                    }
                    .stroke(Color.green, lineWidth: 2)

                    if points.count == 4 {
                        Path { path in
                            path.move(to: points[0])
                            points.dropFirst().forEach { path.addLine(to: $0) }
                            path.closeSubpath()
                        }
                        .fill(Color.green.opacity(0.20))
                    }
                }

                ForEach(points.indices, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        Text("\(i + 1)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .position(points[i])
                }

                VStack {
                    if !measured {
                        instructionBanner
                    }
                    Spacer()
                    if points.count == 4 && !measured {
                        bottomControls(geo: geo)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard points.count < 4, !measured else { return }
                points.append(location)
            }
            .onAppear { viewSize = geo.size }
            .onChange(of: geo.size) { _, new in viewSize = new }
        }
    }

    private var instructionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: errorMessage == nil ? "hand.tap.fill" : "exclamationmark.triangle.fill")
                .font(.caption)
            Text(errorMessage ?? (points.count < 4
                 ? "Tap \(4 - points.count) corner\(points.count == 3 ? "" : "s") of your plot"
                 : "Adjust height & clearance then measure"))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(errorMessage == nil ? .green : .orange)
        .padding(8)
        .background(Color.black.opacity(0.65))
        .cornerRadius(8)
        .padding(.top, 12)
        .padding(.horizontal, 12)
    }

    private func bottomControls(geo: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Camera height: \(String(format: "%.1f", assumedHeight))m")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.green)
                Slider(value: $assumedHeight, in: 0.5...2.5, step: 0.1).accentColor(.green)
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(Color.black.opacity(0.7)).cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Overhead clearance: \(String(format: "%.1f", verticalClearance))m")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.green)
                Slider(value: $verticalClearance, in: 1...20, step: 0.5).accentColor(.green)
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(Color.black.opacity(0.7)).cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Side clearance: \(String(format: "%.1f", horizontalClearance))m")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.green)
                Slider(value: $horizontalClearance, in: 1...20, step: 0.5).accentColor(.green)
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(Color.black.opacity(0.7)).cornerRadius(10)

            HStack(spacing: 16) {
                Button("Reset") {
                    points = []; measured = false; measurement = nil
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(Color.black.opacity(0.6)).cornerRadius(10)

                Button(action: computeMeasurement) {
                    Label("Measure", systemImage: "ruler.fill")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 28).padding(.vertical, 10)
                        .background(Color.green).cornerRadius(10)
                }
            }
        }
        .padding(.bottom, 30)
    }

    private func computeMeasurement() {
        guard points.count == 4, viewSize.width > 0 else { return }
        errorMessage = nil

        let aspectRatio = image.size.height / max(image.size.width, 1)
        let imgW = viewSize.width
        let imgH = imgW * aspectRatio

        let norm = points.map { CGPoint(x: $0.x / imgW, y: $0.y / imgH) }
        let centered = norm.map { (u: ($0.x - 0.5) * 2, v: ($0.y - 0.5) * 2) }

        let pitchRad = max(5.0, min(85.0, pitchDegrees)) * .pi / 180.0
        let H = assumedHeight
        let vFovRad: Double = 60.0 * .pi / 180.0
        let hFovRad: Double = 75.0 * .pi / 180.0

        func groundPoint(u: Double, v: Double) -> (x: Double, y: Double)? {
            let aH = u * (hFovRad / 2)
            let aV = v * (vFovRad / 2)
            let localX = tan(aH)
            let localY = 1.0
            let localZ = -tan(aV)
            let worldX = localX
            let worldY = localY * cos(pitchRad) + localZ * sin(pitchRad)
            let worldZ = -localY * sin(pitchRad) + localZ * cos(pitchRad)
            guard worldZ < -0.001 else { return nil }
            let t = -H / worldZ
            return (x: t * worldX, y: t * worldY)
        }

        var groundPts: [(x: Double, y: Double)] = []
        for p in centered {
            guard let g = groundPoint(u: p.u, v: p.v) else {
                errorMessage = "One of your points is above the horizon — retake the photo pointing more downward."
                return
            }
            groundPts.append(g)
        }

        var shoelace = 0.0
        for i in 0..<groundPts.count {
            let a = groundPts[i]
            let b = groundPts[(i + 1) % groundPts.count]
            shoelace += a.x * b.y - b.x * a.y
        }
        let rawArea = abs(shoelace) / 2.0

        let xs = groundPts.map { $0.x }
        let ys = groundPts.map { $0.y }
        let rawWidth = (xs.max() ?? 0) - (xs.min() ?? 0)
        let rawLength = (ys.max() ?? 0) - (ys.min() ?? 0)

        let area   = min(300.0, max(0.3, rawArea))
        let width  = min(30.0,  max(0.3, rawWidth))
        let length = min(30.0,  max(0.3, rawLength))

        measurement = PlotMeasurement(
            widthMeters: width * 2.5,
            lengthMeters: length * 4.5,
            area: area * 11.25,
            verticalClearance: verticalClearance,
            horizontalClearance: horizontalClearance
        )

        measured = true
        onConfirm()
    }
}

// MARK: - Camera Plot Screen

struct CameraPlotAnalysisView: View {
    @Binding var measurement: PlotMeasurement?
    var onDone: () -> Void

    @State private var capturedImage: UIImage? = nil
    @State private var showingCamera = false
    @State private var showingQuadDraw = false
    @State private var cameraPitch: Double = 45.0

    private let motionManager = CMMotionManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button(action: onDone) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("PLOT SCANNER")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal)
                .padding(.top, 56)

                Spacer()

                if let img = capturedImage, showingQuadDraw {
                    QuadDrawView(
                        image: img,
                        pitchDegrees: cameraPitch,
                        measurement: $measurement,
                        onConfirm: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onDone() }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    instructionView
                }

                Spacer()
            }
        }
        #if !targetEnvironment(simulator)
        .fullScreenCover(isPresented: $showingCamera, onDismiss: {
            if capturedImage != nil { showingQuadDraw = true }
        }) {
            CameraCapture(capturedImage: $capturedImage) { showingCamera = false }
                .ignoresSafeArea()
        }
        #endif
        .onAppear(perform: startMotion)
        .onDisappear(perform: stopMotion)
        .preferredColorScheme(.dark)
    }

    private var instructionView: some View {
        VStack(spacing: 28) {
            Image(systemName: "camera.on.rectangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            VStack(spacing: 10) {
                #if targetEnvironment(simulator)
                Text("Select a Plot Photo")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Running in Simulator — pick a photo\nfrom your library to trace the plot corners.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(white: 0.7))
                    .font(.subheadline)
                #else
                Text("Photograph Your Plot")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Stand at the edge of your planting area.\nPoint the camera down at the ground\nand take a photo of the whole plot.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(white: 0.7))
                    .font(.subheadline)
                #endif
            }

            VStack(alignment: .leading, spacing: 12) {
                stepRow(num: "1", text: "Take a photo of the ground area")
                stepRow(num: "2", text: "Tap the 4 corners of your plot")
                stepRow(num: "3", text: "Set camera height, clearance & tap Measure")
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 24)

            #if targetEnvironment(simulator)
            CameraCapture(capturedImage: $capturedImage) {
                if capturedImage != nil { showingQuadDraw = true }
            }
            #else
            Button(action: { showingCamera = true }) {
                Label("Open Camera", systemImage: "camera.fill")
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(14)
            }
            #endif
        }
        .padding()
    }

    private func stepRow(num: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(num)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 22, height: 22)
                .background(Color.green)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(Color(white: 0.85))
        }
    }

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion else { return }
            let pitchRad = motion.attitude.pitch
            let degrees = pitchRad * 180 / .pi
            cameraPitch = max(10, min(85, degrees))
        }
    }

    private func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Browse Trees Screen

struct BrowseTreesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var sortOption = SortOption.score

    enum SortOption: String, CaseIterable {
        case score = "Score"
        case name  = "Name"
        case cr    = "Resilience"
        case es    = "Environment"
        case ev    = "Ecology"
        case bd    = "Biodiversity"
        case pc    = "Practicality"
    }

    private var displayTrees: [Tree] {
        let filtered = searchText.isEmpty
            ? treeInventory
            : treeInventory.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.scientificName.localizedCaseInsensitiveContains(searchText)
              }
        switch sortOption {
        case .score: return filtered.sorted { $0.score > $1.score }
        case .name:  return filtered.sorted { $0.name < $1.name }
        case .cr:    return filtered.sorted { $0.cr > $1.cr }
        case .es:    return filtered.sorted { $0.es > $1.es }
        case .ev:    return filtered.sorted { $0.ev > $1.ev }
        case .bd:    return filtered.sorted { $0.bd > $1.bd }
        case .pc:    return filtered.sorted { $0.pc > $1.pc }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("STARS TREE DATABASE")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                        Text("Browse trees STARS supports and has data on")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(white: 0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.08))

                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.green)
                        TextField("Search trees...", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 14, design: .monospaced))
                    }
                    .padding(10)
                    .background(Color(white: 0.14))
                    .cornerRadius(10)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    // Sort picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SortOption.allCases, id: \.self) { opt in
                                Button(action: { sortOption = opt }) {
                                    Text(opt.rawValue)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(sortOption == opt ? .black : .green)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(sortOption == opt ? Color.green : Color.green.opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                    }

                    // Tree list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(displayTrees) { tree in
                                BrowseTreeRow(tree: tree)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
        }
    }
}

struct BrowseTreeRow: View {
    let tree: Tree
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                HStack(alignment: .center, spacing: 12) {
                    // Score circle
                    ZStack {
                        Circle()
                            .stroke(scoreColor(tree.score), lineWidth: 2)
                            .frame(width: 44, height: 44)
                        VStack(spacing: 1) {
                            Text(String(format: "%.0f", tree.score))
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(scoreColor(tree.score))
                            Text("SCR")
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    // Name + warning
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            if tree.isLowScore {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 11))
                            }
                            Text(tree.name)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        Text(tree.scientificName)
                            .font(.system(size: 10, design: .monospaced))
                            .italic()
                            .foregroundColor(Color(white: 0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    // Mini score bars
                    VStack(alignment: .trailing, spacing: 3) {
                        miniBar(val: tree.cr, color: .green,  label: "CR")
                        miniBar(val: tree.es, color: .cyan,   label: "ES")
                        miniBar(val: tree.ev, color: .yellow, label: "EV")
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.4))
                }
                .padding(12)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().background(Color(white: 0.2))

                    // Low score warning banner
                    if tree.isLowScore {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Score below 60 — STARS advises against planting this tree.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    // Score breakdown
                    HStack(spacing: 0) {
                        scoreBlock("Resilience", val: tree.cr, color: .green)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        scoreBlock("Environment", val: tree.es, color: .cyan)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        scoreBlock("Ecology", val: tree.ev, color: .yellow)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        scoreBlock("Biodiversity", val: tree.bd, color: .purple)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        scoreBlock("Practicality", val: tree.pc, color: .orange)
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(8)

                    // Physical details
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        detailPill("Max Height", "\(tree.maxHeight)m")
                        detailPill("Max Spread", "\(tree.maxSpread)m")
                        detailPill("Trunk Ø", String(format: "%.2fm", tree.trunkDiameter))
                        detailPill("Water", tree.waterNeeds)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(white: expanded ? 0.1 : 0.12))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(tree.isLowScore ? Color.orange.opacity(0.3) : Color(white: 0.2), lineWidth: 1))
    }

    private func miniBar(val: Int, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color(white: 0.45))
                .frame(width: 14, alignment: .trailing)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.15))
                    .frame(width: 46, height: 5)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: CGFloat(val) / 100.0 * 46, height: 5)
            }
            Text("\(val)")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 22, alignment: .trailing)
        }
    }

    private func scoreBlock(_ label: String, val: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(val)")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func detailPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(white: 0.14))
        .cornerRadius(8)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 70 { return .green }
        if score >= 60 { return Color(red: 0.6, green: 0.9, blue: 0.2) }
        if score >= 50 { return .yellow }
        return .orange
    }
}

// MARK: - Home Screen


// MARK: - Main Survey

// MARK: - Main Home / Hub View

struct TreesToPlant: View {
    @State private var showBrowseSheet = false

    var body: some View {
        homeView
            .preferredColorScheme(.dark)
            .navigationTitle("STARS Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showBrowseSheet) { BrowseTreesView() }
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 62))
                        .foregroundColor(.green)
                }
                Text("TREE SELECTOR")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text("Powered by STARS data")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(white: 0.45))
            }

            Spacer().frame(height: 44)

            VStack(spacing: 12) {
                Button(action: { showBrowseSheet = true }) {
                    homeCardContent(
                        icon: "list.bullet.rectangle.portrait.fill",
                        iconColor: .cyan,
                        title: "Browse All Trees",
                        subtitle: "Explore the full STARS inventory — CR, ES, EV & scores",
                        isPrimary: false
                    )
                }
                
                NavigationLink(destination: STARSRecommendationSurveyView()) {
                    homeCardContent(
                        icon: "slider.horizontal.3",
                        iconColor: .green,
                        title: "Find Trees for My Plot",
                        subtitle: "Step-by-step recommendations based on your site",
                        isPrimary: true
                    )
                }
            }
            .padding(.horizontal, 22)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.green.opacity(0.55))
                Text("Tree data sourced from the STARS program")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(white: 0.3))
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private func homeCardContent(icon: String, iconColor: Color, title: String,
                                 subtitle: String, isPrimary: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(isPrimary ? 0.18 : 0.10))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(white: 0.55))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor.opacity(0.6))
                .padding(.top, 4)
        }
        .padding(14)
        .background(isPrimary ? Color.green.opacity(0.09) : Color(white: 0.09))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13)
            .stroke(isPrimary ? Color.green.opacity(0.45) : Color(white: 0.17), lineWidth: 1))
    }
}

// MARK: - Pushed Survey View

struct STARSRecommendationSurveyView: View {
    @State private var currentStep = 0
    @State private var useCameraMethod = false
    @State private var showCameraScreen = false

    @State private var sunlightExposure = "Full Sun"
    @State private var waterAvailability = "Regular Rainfall"

    @State private var plotMeasurement: PlotMeasurement? = nil

    @State private var verticalClearance = 6.0
    @State private var horizontalSpread  = 6.0
    @State private var areaToPlant       = 20.0

    let inventory: [Tree] = treeInventory

    private var effectiveSpread: Double {
        if useCameraMethod, let m = plotMeasurement { return m.usableSpread }
        return horizontalSpread
    }
    private var effectiveArea: Double {
        if useCameraMethod, let m = plotMeasurement { return m.area }
        return areaToPlant
    }
    private var effectiveVerticalClearance: Double {
        if useCameraMethod, let m = plotMeasurement { return m.verticalClearance }
        return verticalClearance
    }

    private var fittingTrees: [Tree] {
        inventory
            .filter { Double($0.maxHeight) <= effectiveVerticalClearance }
            .filter { Double($0.maxSpread)  <= effectiveSpread }
            .filter { $0.requiredGroundArea <= effectiveArea }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.requiredGroundArea > $1.requiredGroundArea
            }
    }

    private var totalSteps: Int { useCameraMethod ? 2 : 3 }

    private var logicalStep: Int {
        if useCameraMethod {
            return [0, 1, 3][min(currentStep, 2)]
        }
        return currentStep
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Header (Progress indicator / step count)
                if logicalStep < 3 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Step \(currentStep + 1) of \(totalSteps + 1)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            Spacer()
                            Text(stepLabel(logicalStep))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                        ProgressView(value: Double(currentStep), total: Double(totalSteps))
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(Color.black)
                }

                if logicalStep < 3 {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            pageContent
                        }
                        .padding(16)
                    }
                    .background(Color(white: 0.12))
                    .cornerRadius(14)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Fills all vertical space

                    navButtons
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16)
                } else {
                    resultsView(bottomInset: geo.safeAreaInsets.bottom)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black.ignoresSafeArea())
        }
        .navigationTitle("TREE SELECTOR")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false) // Shows default back button back to TreesToPlant home
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showCameraScreen) {
            CameraPlotAnalysisView(measurement: $plotMeasurement) {
                showCameraScreen = false
            }
        }
    }

    private func stepLabel(_ logical: Int) -> String {
        switch logical {
        case 0: return "Environment"
        case 1: return "Input Method"
        case 2: return "Space Constraints"
        default: return "Results"
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private var pageContent: some View {
        switch logicalStep {
        case 0: environmentPage
        case 1: inputMethodPage
        case 2: constraintsPage
        default: EmptyView()
        }
    }

    private var environmentPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Environment").font(.headline).foregroundColor(.green)
            Text("Sunlight Exposure").foregroundColor(Color(white: 0.9))
            Picker("Sunlight", selection: $sunlightExposure) {
                ForEach(["Full Sun", "Partial Shade", "Full Shade"], id: \.self) { Text($0) }
            }.pickerStyle(.segmented)
            Text("Water Availability").foregroundColor(Color(white: 0.9))
            Picker("Water", selection: $waterAvailability) {
                ForEach(["Arid/Low", "Regular Rainfall", "High/Marshy"], id: \.self) { Text($0) }
            }.pickerStyle(.menu).accentColor(.green)
        }
    }

    private var inputMethodPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Measure Your Plot").font(.headline).foregroundColor(.green)
            Text("How would you like to enter your plot dimensions?")
                .foregroundColor(Color(white: 0.75)).font(.subheadline)

            methodCard(
                icon: "camera.viewfinder",
                title: "Scan with Camera",
                subtitle: "Take a photo of your plot, trace its corners, and we'll estimate the dimensions.",
                badge: plotMeasurement != nil ? "✓ Done" : nil,
                selected: useCameraMethod
            ) {
                useCameraMethod = true
                showCameraScreen = true
            }

            methodCard(
                icon: "slider.horizontal.3",
                title: "Enter Manually",
                subtitle: "Use steppers and sliders to set height clearance, spread, and area.",
                badge: nil,
                selected: !useCameraMethod
            ) {
                useCameraMethod = false
            }

            if useCameraMethod, let m = plotMeasurement {
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        statPill("Width",   String(format: "%.1fm", m.widthMeters))
                        statPill("Length",  String(format: "%.1fm", m.lengthMeters))
                        statPill("Area",    String(format: "%.1fm²", m.area))
                        statPill("Overhead", String(format: "%.1fm", m.verticalClearance))
                        statPill("Side",    String(format: "%.1fm", m.horizontalClearance))
                        statPill("Usable",  String(format: "%.1fm", m.usableSpread))
                    }
                    Button("Re-scan") { showCameraScreen = true }
                        .font(.caption).foregroundColor(.green)
                }
                .padding(12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(10)
            }
        }
    }

    private var constraintsPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Space Constraints").font(.headline).foregroundColor(.green)
            Stepper(value: $verticalClearance, in: 1...25, step: 0.5) {
                Text("Vertical Clearance: \(String(format: "%.1f", verticalClearance))m")
                    .foregroundColor(Color(white: 0.9))
            }
            Stepper(value: $horizontalSpread, in: 1...20, step: 0.5) {
                Text("Horizontal Spread: \(String(format: "%.1f", horizontalSpread))m")
                    .foregroundColor(Color(white: 0.9))
            }
            Text("Total Ground Area: \(String(format: "%.1f", areaToPlant)) m²")
                .foregroundColor(Color(white: 0.9))
            Slider(value: $areaToPlant, in: 1...50, step: 0.5).accentColor(.green)
        }
    }

    // MARK: - Navigation

    private var canAdvance: Bool {
        if logicalStep == 1 && useCameraMethod && plotMeasurement == nil { return false }
        return true
    }

    private var navButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") { withAnimation { currentStep -= 1 } }.foregroundColor(.green)
            }
            Spacer()
            Button(currentStep == totalSteps - 1 ? "Analyze" : "Next") {
                withAnimation { currentStep += 1 }
            }
            .buttonStyle(.borderedProminent)
            .tint(canAdvance ? .green : .gray)
            .foregroundColor(.black)
            .disabled(!canAdvance)
        }
    }

    // MARK: - Results

    private func resultsView(bottomInset: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Method badge
                Label(
                    useCameraMethod ? "Camera-measured plot" : "Manual dimensions",
                    systemImage: useCameraMethod ? "camera.fill" : "ruler"
                )
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
                .padding(6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

                // Plot summary
                HStack(spacing: 0) {
                    plotStat("Spread", String(format: "%.1fm", effectiveSpread))
                    Divider().frame(height: 36).background(Color(white: 0.2))
                    plotStat("Area",   String(format: "%.1fm²", effectiveArea))
                    Divider().frame(height: 36).background(Color(white: 0.2))
                    plotStat("Height", String(format: "%.1fm", effectiveVerticalClearance))
                }
                .background(Color(white: 0.1))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))

                if fittingTrees.isEmpty {
                    noMatchView
                } else {
                    treeResultsList
                }

                // Bottom actions
                HStack(spacing: 20) {
                    Button("Adjust") {
                        withAnimation { currentStep = useCameraMethod ? 1 : 2 }
                    }
                    .foregroundColor(.green)
                    if useCameraMethod {
                        Button("Re-scan") { showCameraScreen = true }.foregroundColor(.green)
                    }
                }
                .padding(.top, 4)
                .font(.system(size: 14, design: .monospaced))
            }
            .padding()
            .padding(.bottom, bottomInset > 0 ? bottomInset : 16)   // clear home indicator
        }
    }

    /// The full ordered list: top 1 (biggest section), 2–3 (moderate), rest
    private var treeResultsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            let trees = fittingTrees

            // ── TOP PICK ──
            resultSectionHeader("🏆  Top Pick", color: .green)
            ResultTreeCard(tree: trees[0], rank: 1, tier: .top)

            // ── MODERATE ──
            if trees.count > 1 {
                resultSectionHeader("🌿  Also Recommended", color: .cyan)
                ForEach(Array(trees[1..<min(3, trees.count)].enumerated()), id: \.element.id) { idx, tree in
                    ResultTreeCard(tree: tree, rank: idx + 2, tier: .moderate)
                }
            }

            // ── OTHERS THAT FIT ──
            if trees.count > 3 {
                resultSectionHeader("🌱  Others That Fit", color: Color(white: 0.6))
                ForEach(Array(trees[3...].enumerated()), id: \.element.id) { idx, tree in
                    ResultTreeCard(tree: tree, rank: idx + 4, tier: .other)
                }
            }
        }
    }

    private var noMatchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60)).foregroundColor(.orange)
            Text("No Match Found")
                .font(.title2).bold().foregroundColor(.white)
            Text("No tree in the inventory fits this plot's clearance, spread, and ground area together. Try a larger area, more clearance, or re-scan.")
                .multilineTextAlignment(.center)
                .foregroundColor(Color(white: 0.8))
                .font(.system(size: 13, design: .monospaced))
        }
        .padding()
    }

    private func resultSectionHeader(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.top, 4)
    }

    private func plotStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Reusable subviews (form)

    private func methodCard(icon: String, title: String, subtitle: String,
                            badge: String?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(selected ? .black : .green)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundColor(selected ? .black : .white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundColor(selected ? .black : .green)
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(selected ? .black.opacity(0.7) : Color(white: 0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(14)
            .background(selected ? Color.green : Color(white: 0.18))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.green : Color(white: 0.28), lineWidth: 1))
        }
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.green)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}



// MARK: - Result Tree Card

enum ResultTier { case top, moderate, other }

struct ResultTreeCard: View {
    let tree: Tree
    let rank: Int
    let tier: ResultTier
    @State private var expanded = false

    private var accentColor: Color {
        switch tier {
        case .top:      return .green
        case .moderate: return .cyan
        case .other:    return Color(white: 0.55)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { expanded.toggle() } }) {
                HStack(alignment: .center, spacing: 12) {
                    // Rank badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text("#\(rank)")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            if tree.isLowScore {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 11))
                            }
                            Text(tree.name)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        Text(tree.scientificName)
                            .font(.system(size: 10, design: .monospaced))
                            .italic()
                            .foregroundColor(Color(white: 0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f", tree.score))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(accentColor)
                        Text("score")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(Color(white: 0.45))
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.4))
                }
                .padding(12)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(Color(white: 0.2))

                    if tree.isLowScore {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Score below 60 — STARS advises against planting this tree.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }

                    // CR / ES / EV / BD / PC scores
                    HStack(spacing: 0) {
                        expandedScoreBlock("Resilience", val: tree.cr, color: .green)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        expandedScoreBlock("Environment", val: tree.es, color: .cyan)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        expandedScoreBlock("Ecology", val: tree.ev, color: .yellow)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        expandedScoreBlock("Biodiversity", val: tree.bd, color: .purple)
                        Divider().frame(height: 40).background(Color(white: 0.2))
                        expandedScoreBlock("Practicality", val: tree.pc, color: .orange)
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        miniDetailPill("Height", "\(tree.maxHeight)m")
                        miniDetailPill("Spread", "\(tree.maxSpread)m")
                        miniDetailPill("Water", tree.waterNeeds)
                        miniDetailPill("Trunk Ø", String(format: "%.2fm", tree.trunkDiameter))
                        miniDetailPill("Footprint", String(format: "%.1fm²", tree.requiredGroundArea))
                        miniDetailPill("Trunk req", String(format: "%.1fm²", tree.requiredGroundArea))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(white: expanded ? 0.1 : 0.13))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    tree.isLowScore ? Color.orange.opacity(0.4) : accentColor.opacity(tier == .top ? 0.5 : 0.2),
                    lineWidth: tier == .top ? 1.5 : 1
                )
        )
    }

    private func expandedScoreBlock(_ label: String, val: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(val)")
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func miniDetailPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color(white: 0.14))
        .cornerRadius(7)
    }
}


// MARK: - Preview

#Preview {
    NavigationView {
        TreesToPlant()
    }
}
