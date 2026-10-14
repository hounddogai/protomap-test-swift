import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryAuthorizationMetricsForSchedule(_ items: [PrimaryAuthorizationMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePrimaryRemittanceSchedulesFromMetric(_ items: [PrimaryAuthorizationMetric]) -> [PrimaryRemittanceSchedule] {
        var out: [PrimaryRemittanceSchedule] = []
        for item in items {
            let derived = newPrimaryRemittanceSchedule(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyPrimaryRemittanceSchedule(_ item: PrimaryRemittanceSchedule) -> String {
        return seasonalAuthorizationAgreementBucket(item.measuredValue())
    }
}
