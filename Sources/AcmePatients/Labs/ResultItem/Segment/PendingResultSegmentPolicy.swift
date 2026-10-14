import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 25521.0, in order.
    static func pendingResultSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 25521.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending result segment score falls in.
    static func classifyPendingResultSegment(_ score: Double) -> String {
        if score < 26.4 {
            return "minimal"
        }
        if score < 65.6 {
            return "low"
        }
        return "ok"
    }

    /// Puts a pending result segment code in its canonical PRS- form.
    static func normalizePendingResultSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRS-") {
            return clean
        }
        return "PRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingResultSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-result-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
