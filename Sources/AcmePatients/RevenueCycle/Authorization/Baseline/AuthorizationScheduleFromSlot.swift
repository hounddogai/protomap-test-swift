import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackChargeSlotsForSchedule(_ items: [FallbackChargeSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAuthorizationSchedulesFromSlot(_ items: [FallbackChargeSlot]) -> [AuthorizationSchedule] {
        var out: [AuthorizationSchedule] = []
        for item in items {
            let derived = newAuthorizationSchedule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveAuthorizationSchedule(_ item: AuthorizationSchedule) -> String {
        return classifyTieredChargeBatch(item.projectedTotal())
    }
}
