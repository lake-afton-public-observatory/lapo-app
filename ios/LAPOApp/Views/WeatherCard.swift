import SwiftUI

struct WeatherCard: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tonight's Weather", systemImage: "cloud.sun.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)
                .textCase(.uppercase)

            if let weather = store.weather {
                Text("\(Int(weather.temperature.fahrenheit.rounded()))°F")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let condition = weather.weather.first {
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(.white.opacity(0.4))
                        Text(condition.longDescription.capitalized)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .font(.system(size: 14))
                }

                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(Int(weather.wind.speed.milesPerHour.rounded())) mph · \(weather.clouds ?? 0)% clouds")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .font(.system(size: 14))
            } else {
                Text("–")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    WeatherCard()
        .environmentObject(AppStore())
        .padding()
        .background(Color.black)
}
