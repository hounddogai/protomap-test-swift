import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultNetworkRecordsForNotice(_ items: [DefaultNetworkRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingFollowUpNoticesFromRecord(_ items: [DefaultNetworkRecord]) -> [PendingFollowUpNotice] {
        var out: [PendingFollowUpNotice] = []
        for item in items {
            let derived = newPendingFollowUpNotice(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPendingFollowUpNotice(_ item: PendingFollowUpNotice) -> String {
        return normalizeManualNetworkForecastCode(item.code)
    }
}
