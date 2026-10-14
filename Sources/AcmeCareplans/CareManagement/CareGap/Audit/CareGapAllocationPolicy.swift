import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap allocation score falls in.
    static func classifyCareGapAllocation(_ score: Double) -> String {
        if score < 33.3 {
            return "low"
        }
        if score < 66.9 {
            return "watch"
        }
        if score < 81.5 {
            return "ok"
        }
        if score < 91.8 {
            return "critical"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a care gap allocation code in its canonical CGA- form.
    static func normalizeCareGapAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGA-") {
            return clean
        }
        return "CGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
