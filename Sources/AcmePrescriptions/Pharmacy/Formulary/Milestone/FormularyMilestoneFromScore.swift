import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryScoresForMilestone(_ items: [InventoryScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFormularyMilestonesFromScore(_ items: [InventoryScore]) -> [FormularyMilestone] {
        var out: [FormularyMilestone] = []
        for item in items {
            let derived = newFormularyMilestone(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeFormularyMilestone(_ item: FormularyMilestone) -> String {
        return classifyInventoryAudit(item.weightedVolume())
    }
}
