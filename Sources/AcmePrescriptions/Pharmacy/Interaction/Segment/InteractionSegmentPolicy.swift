import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a interaction segment code in its canonical IS- form.
    static func normalizeInteractionSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IS-") {
            return clean
        }
        return "IS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a interaction segment score falls in.
    static func classifyInteractionSegment(_ score: Double) -> String {
        if score < 50.9 {
            return "high"
        }
        if score < 84.4 {
            return "ok"
        }
        return "minimal"
    }
}
