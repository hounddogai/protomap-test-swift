import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryTargetsForMilestone(_ items: [InventoryTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDefaultInteractionMilestonesFromTarget(_ items: [InventoryTarget]) -> [DefaultInteractionMilestone] {
        var out: [DefaultInteractionMilestone] = []
        for item in items {
            let derived = newDefaultInteractionMilestone(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDefaultInteractionMilestone(_ item: DefaultInteractionMilestone) -> String {
        return classifyInventoryTarget(item.netExposure())
    }
}
