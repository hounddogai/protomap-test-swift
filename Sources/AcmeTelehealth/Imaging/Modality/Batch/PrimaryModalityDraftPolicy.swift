import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a primary modality draft code in its canonical PMD- form.
    static func normalizePrimaryModalityDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PMD-") {
            return clean
        }
        return "PMD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryModalityDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-modality-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryModalityDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
