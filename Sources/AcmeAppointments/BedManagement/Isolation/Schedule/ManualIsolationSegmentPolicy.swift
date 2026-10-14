import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 39387.0, in order.
    static func manualIsolationSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39387.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualIsolationSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-isolation-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a manual isolation segment score falls in.
    static func classifyManualIsolationSegment(_ score: Double) -> String {
        if score < 4.6 {
            return "high"
        }
        if score < 52.6 {
            return "minimal"
        }
        if score < 84.4 {
            return "elevated"
        }
        return "low"
    }

    /// Puts a manual isolation segment code in its canonical MIS- form.
    static func normalizeManualIsolationSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MIS-") {
            return clean
        }
        return "MIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
