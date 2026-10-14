import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveClaimSnapshotsForRecord(_ items: [AdaptiveClaimSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveChargeRecordsFromSnapshot(_ items: [AdaptiveClaimSnapshot]) -> [ChargeRecord] {
        var out: [ChargeRecord] = []
        for item in items {
            let derived = newChargeRecord(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchChargeRecord(_ item: ChargeRecord) -> String {
        return normalizeClaimReservationCode(item.code)
    }
}
