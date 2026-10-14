import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a remittance segment code in its canonical RS- form.
    static func normalizeRemittanceSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RS-") {
            return clean
        }
        return "RS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a remittance segment score falls in.
    static func classifyRemittanceSegment(_ score: Double) -> String {
        if score < 38.3 {
            return "ok"
        }
        if score < 49.4 {
            return "low"
        }
        return "medium"
    }
}
