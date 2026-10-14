import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a discharge plan entry score falls in.
    static func classifyDischargePlanEntry(_ score: Double) -> String {
        if score < 4.0 {
            return "elevated"
        }
        if score < 36.8 {
            return "ok"
        }
        if score < 60.6 {
            return "critical"
        }
        if score < 67.2 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a discharge plan entry code in its canonical DPE- form.
    static func normalizeDischargePlanEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPE-") {
            return clean
        }
        return "DPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
