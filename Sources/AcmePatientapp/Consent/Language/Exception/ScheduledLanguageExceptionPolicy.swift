import AcmePlatform
import Foundation

extension Consent {
    /// Puts a scheduled language exception code in its canonical SLE- form.
    static func normalizeScheduledLanguageExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SLE-") {
            return clean
        }
        return "SLE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledLanguageExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledLanguageException() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-language-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledLanguageExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
