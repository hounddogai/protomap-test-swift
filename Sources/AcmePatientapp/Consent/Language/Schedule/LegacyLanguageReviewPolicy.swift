import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 61122.0, in order.
    static func legacyLanguageReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61122.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a legacy language review code in its canonical LLR- form.
    static func normalizeLegacyLanguageReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LLR-") {
            return clean
        }
        return "LLR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyLanguageReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyLanguageReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-language-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
