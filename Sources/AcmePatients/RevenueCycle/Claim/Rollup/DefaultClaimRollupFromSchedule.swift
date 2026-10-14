import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveStatementSchedulesForRollup(_ items: [AdaptiveStatementSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDefaultClaimRollupsFromSchedule(_ items: [AdaptiveStatementSchedule]) -> [DefaultClaimRollup] {
        var out: [DefaultClaimRollup] = []
        for item in items {
            let derived = newDefaultClaimRollup(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveDefaultClaimRollup(_ item: DefaultClaimRollup) -> String {
        return normalizeBatchedStatementReservationCode(item.code)
    }
}
