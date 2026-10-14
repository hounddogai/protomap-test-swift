import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a legacy charge score score falls in.
    static func classifyLegacyChargeScore(_ score: Double) -> String {
        if score < 60.6 {
            return "low"
        }
        if score < 74.7 {
            return "elevated"
        }
        if score < 88.3 {
            return "high"
        }
        return "ok"
    }

    static func legacyChargeScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyChargeScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-charge-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy charge score code in its canonical LCS- form.
    static func normalizeLegacyChargeScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCS-") {
            return clean
        }
        return "LCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
