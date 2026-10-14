import AcmePlatform
import Foundation

extension Labs {
    /// Puts a primary reference range bundle code in its canonical PRRB- form.
    static func normalizePrimaryReferenceRangeBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRRB-") {
            return clean
        }
        return "PRRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryReferenceRangeBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryReferenceRangeBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-reference-range-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary reference range bundle score falls in.
    static func classifyPrimaryReferenceRangeBundle(_ score: Double) -> String {
        if score < 14.0 {
            return "elevated"
        }
        if score < 17.3 {
            return "critical"
        }
        if score < 30.0 {
            return "ok"
        }
        return "minimal"
    }
}
