import SwiftUI

struct WhatsUpList: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Next Session", systemImage: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            if let objects = store.whatsUp?.objects, !objects.isEmpty {
                VStack(spacing: 0) {
                    // Identify rows by their array position, not SkyObject.id (== name) --
                    // two objects can legitimately share a name (e.g. multiple "Unknown"
                    // entries from the empty-name-array decode fallback), and SwiftUI
                    // silently collapses ForEach rows that share an id, dropping any
                    // object past the first with a given name from the rendered list.
                    ForEach(Array(objects.enumerated()), id: \.offset) { index, obj in
                        SkyObjectRow(object: obj)
                        if index < objects.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 20)
                        }
                    }
                }
            } else if store.whatsUp != nil {
                Text("No objects found for the next session.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            } else {
                // Loading shimmer rows
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        ShimmerRow()
                    }
                }
            }

            Spacer(minLength: 0)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct SkyObjectRow: View {
    let object: SkyObject

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(object.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(object.brightnessLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Text(String(format: "%.1f", object.magnitude))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct ShimmerRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 70, height: 10)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

#Preview {
    WhatsUpList()
        .environmentObject(AppStore())
        .padding()
        .background(Color.black)
}
