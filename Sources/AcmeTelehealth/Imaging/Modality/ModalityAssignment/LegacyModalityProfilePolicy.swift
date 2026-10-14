import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 67189.0, in order.
    static func legacyModalityProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67189.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyModalityProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-modality-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy modality profile code in its canonical LMP- form.
    static func normalizeLegacyModalityProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LMP-") {
            return clean
        }
        return "LMP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy modality profile score falls in.
    static func classifyLegacyModalityProfile(_ score: Double) -> String {
        if score < 75.6 {
            return "ok"
        }
        if score < 96.1 {
            return "medium"
        }
        return "critical"
    }
}
