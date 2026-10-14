import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolBatchesForTier(_ items: [CareProtocolBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePrimaryTaskTiersFromBatch(_ items: [CareProtocolBatch]) -> [PrimaryTaskTier] {
        var out: [PrimaryTaskTier] = []
        for item in items {
            let derived = newPrimaryTaskTier(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePrimaryTaskTier(_ item: PrimaryTaskTier) -> String {
        return classifyCareProtocolBatch(item.projectedTotal())
    }
}
