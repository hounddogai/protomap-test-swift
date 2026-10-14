import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a strict slot record score falls in.
    static func classifyStrictSlotRecord(_ score: Double) -> String {
        if score < 7.0 {
            return "low"
        }
        if score < 87.5 {
            return "medium"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictSlotRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-slot-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict slot record code in its canonical SSR- form.
    static func normalizeStrictSlotRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSR-") {
            return clean
        }
        return "SSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
