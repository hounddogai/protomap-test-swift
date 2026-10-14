import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeBatchedTaskPlansForManifest(_ items: [BatchedTaskPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRegionalCareProtocolManifestsFromPlan(_ items: [BatchedTaskPlan]) -> [RegionalCareProtocolManifest] {
        var out: [RegionalCareProtocolManifest] = []
        for item in items {
            let derived = newRegionalCareProtocolManifest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateRegionalCareProtocolManifest(_ item: RegionalCareProtocolManifest) -> String {
        return normalizeTaskSlotCode(item.code)
    }
}
