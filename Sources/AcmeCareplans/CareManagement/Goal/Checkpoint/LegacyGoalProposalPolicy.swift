import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyGoalProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-goal-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeLegacyGoalProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy goal proposal code in its canonical LGP- form.
    static func normalizeLegacyGoalProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LGP-") {
            return clean
        }
        return "LGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
