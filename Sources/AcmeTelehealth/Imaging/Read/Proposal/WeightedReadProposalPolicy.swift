import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 78438.0, in order.
    static func weightedReadProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78438.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeWeightedReadProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedReadProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-read-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a weighted read proposal code in its canonical WRP- form.
    static func normalizeWeightedReadProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WRP-") {
            return clean
        }
        return "WRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
