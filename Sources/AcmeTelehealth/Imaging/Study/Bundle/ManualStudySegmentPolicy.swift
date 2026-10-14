import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a manual study segment code in its canonical MSS- form.
    static func normalizeManualStudySegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MSS-") {
            return clean
        }
        return "MSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualStudySegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 53826.0, in order.
    static func manualStudySegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53826.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualStudySegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-study-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
