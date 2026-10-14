import AcmePlatform
import Foundation

extension Imaging {
    static func adaptiveModalityRequestSpan(_ start: Int, end: Int) -> Int {
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
    static func probeAdaptiveModalityRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-modality-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a adaptive modality request code in its canonical AMR- form.
    static func normalizeAdaptiveModalityRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AMR-") {
            return clean
        }
        return "AMR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 45701.0, in order.
    static func adaptiveModalityRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45701.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
