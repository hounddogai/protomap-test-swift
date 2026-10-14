import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedDisclosureTargetsForBatch(_ items: [CappedDisclosureTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRegionalRevocationBatchesFromTarget(_ items: [CappedDisclosureTarget]) -> [RegionalRevocationBatch] {
        var out: [RegionalRevocationBatch] = []
        for item in items {
            let derived = newRegionalRevocationBatch(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalRevocationBatch(_ item: RegionalRevocationBatch) -> String {
        return classifyCappedDisclosureTarget(item.adjustedTotal())
    }
}
