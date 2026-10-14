import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilitySummariesForWindow(_ items: [EligibilitySummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveManualNetworkWindowsFromSummary(_ items: [EligibilitySummary]) -> [ManualNetworkWindow] {
        var out: [ManualNetworkWindow] = []
        for item in items {
            let derived = newManualNetworkWindow(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveManualNetworkWindow(_ item: ManualNetworkWindow) -> String {
        return eligibilityReservationBucket(item.netVolume())
    }
}
