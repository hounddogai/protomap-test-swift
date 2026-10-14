import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackInteractionBundlesForNotice(_ items: [FallbackInteractionBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveWeightedRecallNoticesFromBundle(_ items: [FallbackInteractionBundle]) -> [WeightedRecallNotice] {
        var out: [WeightedRecallNotice] = []
        for item in items {
            let derived = newWeightedRecallNotice(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedRecallNotice(_ item: WeightedRecallNotice) -> String {
        return normalizeGlobalInteractionAssignmentCode(item.code)
    }
}
