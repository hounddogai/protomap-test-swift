import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictFormularyScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-formulary-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict formulary score code in its canonical SFS- form.
    static func normalizeStrictFormularyScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFS-") {
            return clean
        }
        return "SFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict formulary score score falls in.
    static func classifyStrictFormularyScore(_ score: Double) -> String {
        if score < 34.8 {
            return "elevated"
        }
        if score < 57.2 {
            return "watch"
        }
        if score < 94.0 {
            return "low"
        }
        return "minimal"
    }

    static func mergeStrictFormularyScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
