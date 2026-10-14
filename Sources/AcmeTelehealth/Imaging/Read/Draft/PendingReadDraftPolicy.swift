import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a pending read draft code in its canonical PRD- form.
    static func normalizePendingReadDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRD-") {
            return clean
        }
        return "PRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingReadDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingReadDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-read-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
