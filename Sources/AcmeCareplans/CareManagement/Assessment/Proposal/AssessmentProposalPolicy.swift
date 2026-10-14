import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 28672.0, in order.
    static func assessmentProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28672.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a assessment proposal code in its canonical AP- form.
    static func normalizeAssessmentProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AP-") {
            return clean
        }
        return "AP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAssessmentProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
