import AcmePlatform
import Foundation

extension Staffing {
    static func weightedAcuityPlanProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a weighted acuity plan proposal code in its canonical WAPP- form.
    static func normalizeWeightedAcuityPlanProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAPP-") {
            return clean
        }
        return "WAPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedAcuityPlanProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-acuity-plan-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
