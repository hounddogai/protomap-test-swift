import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a worklist template score falls in.
    static func classifyWorklistTemplate(_ score: Double) -> String {
        if score < 6.3 {
            return "watch"
        }
        if score < 9.7 {
            return "low"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a worklist template code in its canonical WT- form.
    static func normalizeWorklistTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WT-") {
            return clean
        }
        return "WT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWorklistTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
