import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffMappingsForTemplate(_ items: [HandoffMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveManualOrderSetTemplatesFromMapping(_ items: [HandoffMapping]) -> [ManualOrderSetTemplate] {
        var out: [ManualOrderSetTemplate] = []
        for item in items {
            let derived = newManualOrderSetTemplate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleManualOrderSetTemplate(_ item: ManualOrderSetTemplate) -> Double {
        return handoffManifestWeight(1, active: true)
    }
}
