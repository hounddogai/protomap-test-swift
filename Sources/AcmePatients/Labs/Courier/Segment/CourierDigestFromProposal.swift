import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultProposalsForDigest(_ items: [ResultProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCourierDigestsFromProposal(_ items: [ResultProposal]) -> [CourierDigest] {
        var out: [CourierDigest] = []
        for item in items {
            let derived = newCourierDigest(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyCourierDigestExtra(_ item: CourierDigest) -> Double {
        return lenientResultAgreementWeight(3, active: true)
    }
}
