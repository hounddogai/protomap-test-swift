import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeWeightedRecallDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedRecallDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-recall-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a weighted recall draft code in its canonical WRD- form.
    static func normalizeWeightedRecallDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRD-") {
            return clean
        }
        return "WRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
