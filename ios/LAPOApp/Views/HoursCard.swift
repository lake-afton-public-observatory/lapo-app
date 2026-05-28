import SwiftUI

struct HoursCard: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This Weekend", systemImage: "clock.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)
                .textCase(.uppercase)

            if let hours = store.hours?.hours {
                Text(hours.prettyHours)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Friday & Saturday")
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
    HoursCard()
        .environmentObject(AppStore())
        .padding()
        .background(Color.black)
}
