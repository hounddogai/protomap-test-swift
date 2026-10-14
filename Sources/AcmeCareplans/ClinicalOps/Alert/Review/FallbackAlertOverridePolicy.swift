import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a fallback alert override code in its canonical FAO- form.
    static func normalizeFallbackAlertOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FAO-") {
            return clean
        }
        return "FAO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackAlertOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackAlertOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-alert-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackAlertOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
