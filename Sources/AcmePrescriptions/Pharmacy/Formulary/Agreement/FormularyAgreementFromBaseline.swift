import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryBaselinesForAgreement(_ items: [InventoryBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveFormularyAgreementsFromBaseline(_ items: [InventoryBaseline]) -> [FormularyAgreement] {
        var out: [FormularyAgreement] = []
        for item in items {
            let derived = newFormularyAgreement(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyFormularyAgreement(_ item: FormularyAgreement) -> Double {
        return rollingInventoryScheduleWeight(6, active: true)
    }
}
