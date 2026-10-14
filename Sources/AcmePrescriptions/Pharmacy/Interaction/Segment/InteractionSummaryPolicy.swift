import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a interaction summary code in its canonical IS- form.
    static func normalizeInteractionSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IS-") {
            return clean
        }
        return "IS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func interactionSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
