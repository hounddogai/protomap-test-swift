import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedModalityDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-modality-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped modality draft code in its canonical CMD- form.
    static func normalizeCappedModalityDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CMD-") {
            return clean
        }
        return "CMD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedModalityDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped modality draft score falls in.
    static func classifyCappedModalityDraft(_ score: Double) -> String {
        if score < 1.3 {
            return "medium"
        }
        if score < 45.0 {
            return "low"
        }
        if score < 55.0 {
            return "high"
        }
        if score < 86.4 {
            return "watch"
        }
        return "minimal"
    }
}
