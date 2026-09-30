import SwiftUI

struct VisiblePlanetsList: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Visible Now", systemImage: "circle.hexagongrid.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            if let planets = store.visiblePlanets, !planets.isEmpty {
                VStack(spacing: 0) {
                    // Same reasoning as WhatsUpList -- identify rows by array
                    // position, not VisiblePlanet.id (== name), so two entries
                    // sharing a name never collapse into one rendered row.
                    ForEach(Array(planets.enumerated()), id: \.offset) { index, planet in
                        VisiblePlanetRow(planet: planet)
                        if index < planets.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 20)
                        }
                    }
                }
            } else if store.visiblePlanets != nil {
                Text("No planets currently above the horizon.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        PlanetShimmerRow()
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

private struct VisiblePlanetRow: View {
    let planet: VisiblePlanet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(planet.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(planet.brightness.capitalized) · \(planet.constellation)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Text("\(Int(planet.altitudeDegrees.rounded()))°")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct PlanetShimmerRow: View {
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
    VisiblePlanetsList()
        .environmentObject(AppStore())
        .padding()
        .background(Color.black)
}
