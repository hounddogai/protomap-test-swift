import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePendingChargeOverridesForRecord(_ items: [PendingChargeOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationRecordsFromOverride(_ items: [PendingChargeOverride]) -> [AuthorizationRecord] {
        var out: [AuthorizationRecord] = []
        for item in items {
            let derived = newAuthorizationRecord(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAuthorizationRecord(_ item: AuthorizationRecord) -> String {
        return defaultChargeReviewBucket(item.netExposure())
    }
}
