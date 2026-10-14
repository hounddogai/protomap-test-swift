import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackModalityEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-modality-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback modality entry code in its canonical FME- form.
    static func normalizeFallbackModalityEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FME-") {
            return clean
        }
        return "FME-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback modality entry score falls in.
    static func classifyFallbackModalityEntry(_ score: Double) -> String {
        if score < 41.5 {
            return "high"
        }
        if score < 51.9 {
            return "low"
        }
        if score < 95.7 {
            return "minimal"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 64794.0, in order.
    static func fallbackModalityEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64794.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
