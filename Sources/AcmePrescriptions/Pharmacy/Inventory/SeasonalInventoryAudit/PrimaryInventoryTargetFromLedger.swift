import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveInteractionLedgersForTarget(_ items: [AdaptiveInteractionLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePrimaryInventoryTargetsFromLedger(_ items: [AdaptiveInteractionLedger]) -> [PrimaryInventoryTarget] {
        var out: [PrimaryInventoryTarget] = []
        for item in items {
            let derived = newPrimaryInventoryTarget(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPrimaryInventoryTarget(_ item: PrimaryInventoryTarget) -> String {
        return classifyWeightedInteractionDigest(item.measuredValue())
    }
}
