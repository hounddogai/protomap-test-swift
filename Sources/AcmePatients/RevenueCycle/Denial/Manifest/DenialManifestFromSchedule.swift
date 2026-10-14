import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceSchedulesForManifest(_ items: [RemittanceSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDenialManifestsFromSchedule(_ items: [RemittanceSchedule]) -> [DenialManifest] {
        var out: [DenialManifest] = []
        for item in items {
            let derived = newDenialManifest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleDenialManifest(_ item: DenialManifest) -> String {
        return remittanceAuditBucket(item.measuredValue())
    }
}
