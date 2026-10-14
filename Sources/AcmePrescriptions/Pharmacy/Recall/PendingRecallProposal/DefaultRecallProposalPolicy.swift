import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultRecallProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-recall-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default recall proposal score falls in.
    static func classifyDefaultRecallProposal(_ score: Double) -> String {
        if score < 15.0 {
            return "minimal"
        }
        if score < 59.5 {
            return "high"
        }
        if score < 75.1 {
            return "medium"
        }
        if score < 77.7 {
            return "ok"
        }
        return "elevated"
    }

    /// Puts a default recall proposal code in its canonical DRP- form.
    static func normalizeDefaultRecallProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRP-") {
            return clean
        }
        return "DRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
