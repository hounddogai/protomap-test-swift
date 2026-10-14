import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffDraftsForVariance(_ items: [HandoffDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveOrderSetVariancesFromDraft(_ items: [HandoffDraft]) -> [OrderSetVariance] {
        var out: [OrderSetVariance] = []
        for item in items {
            let derived = newOrderSetVariance(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveOrderSetVariance(_ item: OrderSetVariance) -> String {
        return classifyHandoffAgreement(item.weightedValue())
    }
}
