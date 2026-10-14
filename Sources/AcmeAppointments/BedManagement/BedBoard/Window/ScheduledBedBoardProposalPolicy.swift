import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledBedBoardProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-bed-board-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled bed board proposal code in its canonical SBBP- form.
    static func normalizeScheduledBedBoardProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SBBP-") {
            return clean
        }
        return "SBBP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
