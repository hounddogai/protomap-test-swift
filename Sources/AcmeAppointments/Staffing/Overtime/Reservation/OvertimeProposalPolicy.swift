import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a overtime proposal score falls in.
    static func classifyOvertimeProposal(_ score: Double) -> String {
        if score < 59.5 {
            return "low"
        }
        if score < 60.7 {
            return "watch"
        }
        if score < 68.7 {
            return "critical"
        }
        if score < 95.3 {
            return "high"
        }
        return "medium"
    }

    static func overtimeProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a overtime proposal code in its canonical OP- form.
    static func normalizeOvertimeProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OP-") {
            return clean
        }
        return "OP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
