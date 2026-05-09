import SwiftUI

struct FlipClockViewWrapper: View {
    let use24Hour: Bool
    let showSeconds: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            FlipClockView(date: context.date, use24Hour: use24Hour, showSeconds: showSeconds)
        }
    }
}

struct FlipClockView: View {
    let date: Date
    let use24Hour: Bool
    let showSeconds: Bool

    private var hourString: String {
        let hour = Calendar.current.component(.hour, from: date)
        return String(format: "%02d", use24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12))
    }

    private var minuteString: String {
        String(format: "%02d", Calendar.current.component(.minute, from: date))
    }

    private var secondString: String {
        String(format: "%02d", Calendar.current.component(.second, from: date))
    }

    private var colonOn: Bool {
        Calendar.current.component(.second, from: date) % 2 == 0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                HStack(spacing: digitFontSize * 0.25) {
                    digitGroup(hourString)

                    if !showSeconds {
                        Text(":")
                            .font(.system(size: digitFontSize * 0.58, weight: .heavy))
                            .foregroundStyle(Color(white: 0.58))
                            .opacity(colonOn ? 1.0 : 0.08)
                            .animation(.easeInOut(duration: 0.2), value: colonOn)
                            .frame(width: digitFontSize * 0.22)
                    }

                    digitGroup(minuteString)

                    if showSeconds {
                        digitGroup(secondString)
                    }
                }

                if !use24Hour {
                    Text(Calendar.current.component(.hour, from: date) >= 12 ? "PM" : "AM")
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.45))
                }

                dateView
            }
        }
    }

    private func digitGroup(_ string: String) -> some View {
        HStack(spacing: 6) {
            DigitCardView(digit: string.first!, fontSize: digitFontSize)
            DigitCardView(digit: string.last!, fontSize: digitFontSize)
        }
    }

    private var dateView: some View {
        Text(date.formatted(.dateTime.year().month().day().weekday()))
            .font(.system(size: 28, weight: .regular))
            .foregroundStyle(Color(white: 0.30))
            .padding(.top, DS.Spacing.lg)
    }

    private var digitFontSize: CGFloat {
        let baseWidth = NSScreen.screens.first?.frame.width ?? 1920
        return baseWidth > 2000 ? 225 : 175
    }
}

// MARK: - DigitCardView
//
// 4-layer split-flap rendering:
//   Layer 1 (bg): top half = next digit, bottom half = current digit
//   Layer 2 (top flap): current top half, rotates 0° → -90° (falls backward)
//   Layer 3 (bottom flap): next bottom half, rotates +90° → 0° (unfolds forward)
//   Divider: center gap line

private struct DigitCardView: View {
    let digit: Character
    let fontSize: CGFloat

    @State private var current: Character = "0"
    @State private var next: Character = "0"
    @State private var topFlapAngle: Double = 0
    @State private var bottomFlapAngle: Double = 0
    @State private var isFlipping = false

    private var cardW: CGFloat { fontSize * 0.66 }
    private var cardH: CGFloat { fontSize * 1.68 }
    private var halfH: CGFloat { cardH / 2 }
    private var radius: CGFloat { cardH * 0.055 }

    var body: some View {
        ZStack {
            // Background: top = next, bottom = current
            VStack(spacing: 0) {
                halfFace(next, isTop: true)
                halfFace(current, isTop: false)
            }

            // Center divider
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(height: 1.5)

            // Top flap: current top half, falls backward (0° → -90°)
            halfFace(current, isTop: true)
                .rotation3DEffect(
                    .degrees(topFlapAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.38
                )
                .frame(width: cardW, height: cardH, alignment: .top)
                .zIndex(2)

            // Bottom flap: next bottom half, unfolds forward (+90° → 0°)
            halfFace(next, isTop: false)
                .rotation3DEffect(
                    .degrees(bottomFlapAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.38
                )
                .frame(width: cardW, height: cardH, alignment: .bottom)
                .zIndex(2)
        }
        .frame(width: cardW, height: cardH)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .shadow(color: .black.opacity(0.55), radius: 8, y: 4)
        .onChange(of: digit) { _, newVal in
            guard newVal != current else { return }
            flipTo(newVal)
        }
        .onAppear {
            current = digit
            next = digit
            topFlapAngle = 0
            bottomFlapAngle = 0
        }
    }

    private func halfFace(_ value: Character, isTop: Bool) -> some View {
        ZStack {
            Color(white: isTop ? 0.09 : 0.045)
            Text(String(value))
                .font(.system(size: fontSize, weight: .heavy))
                .fontWidth(.condensed)
                .foregroundStyle(Color(red: 0.78, green: 0.80, blue: 0.84))
        }
        .frame(width: cardW, height: cardH)
        .frame(height: halfH, alignment: isTop ? .top : .bottom)
        .clipped()
    }

    private func flipTo(_ newVal: Character) {
        guard !isFlipping else {
            current = newVal
            next = newVal
            return
        }

        isFlipping = true

        // Reset top flap to 0° (visually seamless: current == next at this point)
        topFlapAngle = 0
        next = newVal          // Background top now shows new value; top flap still shows old
        bottomFlapAngle = 90   // Bottom flap starts edge-on

        // Phase 1: top flap falls backward (0° → -90°)
        withAnimation(.easeIn(duration: 0.24)) {
            topFlapAngle = -90
        }

        // Phase 2: bottom flap unfolds forward (+90° → 0°), slight overlap with phase 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeOut(duration: 0.28)) {
                self.bottomFlapAngle = 0
            }
        }

        // Finalize: commit new value; topFlapAngle stays at -90° until next flip resets it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
            self.current = newVal
            self.isFlipping = false
        }
    }
}
