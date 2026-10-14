import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackInventoryBaselinesForAudit(_ items: [FallbackInventoryBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveInteractionAuditsFromBaseline(_ items: [FallbackInventoryBaseline]) -> [InteractionAudit] {
        var out: [InteractionAudit] = []
        for item in items {
            let derived = newInteractionAudit(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveInteractionAudit(_ item: InteractionAudit) -> Double {
        return fallbackInventoryBaselineWeight(9, active: true)
    }
}
