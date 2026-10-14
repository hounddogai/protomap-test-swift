import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedHandoffMappingsForEstimate(_ items: [CappedHandoffMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStrictRoundingEstimatesFromMapping(_ items: [CappedHandoffMapping]) -> [StrictRoundingEstimate] {
        var out: [StrictRoundingEstimate] = []
        for item in items {
            let derived = newStrictRoundingEstimate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveStrictRoundingEstimate(_ item: StrictRoundingEstimate) -> String {
        return classifyHandoffProposal(item.measuredValue())
    }
}
