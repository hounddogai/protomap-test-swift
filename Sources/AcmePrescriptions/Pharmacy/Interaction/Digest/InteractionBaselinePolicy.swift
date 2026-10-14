import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func interactionBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a interaction baseline score falls in.
    static func classifyInteractionBaseline(_ score: Double) -> String {
        if score < 26.1 {
            return "low"
        }
        if score < 68.6 {
            return "elevated"
        }
        if score < 82.7 {
            return "ok"
        }
        return "watch"
    }

    /// Puts a interaction baseline code in its canonical IB- form.
    static func normalizeInteractionBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IB-") {
            return clean
        }
        return "IB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
