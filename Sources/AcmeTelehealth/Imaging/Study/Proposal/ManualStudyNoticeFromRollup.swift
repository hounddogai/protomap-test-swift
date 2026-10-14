import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWeightedCareProtocolRollupsForNotice(_ items: [WeightedCareProtocolRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveManualStudyNoticesFromRollup(_ items: [WeightedCareProtocolRollup]) -> [ManualStudyNotice] {
        var out: [ManualStudyNotice] = []
        for item in items {
            let derived = newManualStudyNotice(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateManualStudyNotice(_ item: ManualStudyNotice) -> String {
        return normalizeWeightedCareProtocolRollupCode(item.code)
    }
}
