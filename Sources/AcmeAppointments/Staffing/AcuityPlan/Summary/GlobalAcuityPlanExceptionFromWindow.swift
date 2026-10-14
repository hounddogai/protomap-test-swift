import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalCredentialWindowsForException(_ items: [GlobalCredentialWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveGlobalAcuityPlanExceptionsFromWindow(_ items: [GlobalCredentialWindow]) -> [GlobalAcuityPlanException] {
        var out: [GlobalAcuityPlanException] = []
        for item in items {
            let derived = newGlobalAcuityPlanException(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileGlobalAcuityPlanException(_ item: GlobalAcuityPlanException) -> String {
        return normalizeLegacyCredentialSlotCode(item.code)
    }
}
