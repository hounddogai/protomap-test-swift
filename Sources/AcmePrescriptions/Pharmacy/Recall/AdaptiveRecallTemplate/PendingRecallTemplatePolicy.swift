import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingRecallTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-recall-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a pending recall template code in its canonical PRT- form.
    static func normalizePendingRecallTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRT-") {
            return clean
        }
        return "PRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingRecallTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
