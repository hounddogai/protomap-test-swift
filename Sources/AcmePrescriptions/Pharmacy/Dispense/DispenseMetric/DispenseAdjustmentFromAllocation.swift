import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInteractionAllocationsForAdjustment(_ items: [PrimaryInteractionAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveDispenseAdjustmentsFromAllocation(_ items: [PrimaryInteractionAllocation]) -> [DispenseAdjustment] {
        var out: [DispenseAdjustment] = []
        for item in items {
            let derived = newDispenseAdjustment(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeDispenseAdjustment(_ item: DispenseAdjustment) -> String {
        return classifyPrimaryInteractionTemplate(item.measuredValue())
    }
}
