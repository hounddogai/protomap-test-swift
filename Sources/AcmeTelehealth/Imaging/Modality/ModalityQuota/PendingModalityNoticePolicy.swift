import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a pending modality notice score falls in.
    static func classifyPendingModalityNotice(_ score: Double) -> String {
        if score < 4.8 {
            return "high"
        }
        if score < 51.4 {
            return "ok"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingModalityNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-modality-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePendingModalityNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a pending modality notice code in its canonical PMN- form.
    static func normalizePendingModalityNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PMN-") {
            return clean
        }
        return "PMN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
