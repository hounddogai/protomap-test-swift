import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultResultAuditsForSchedule(_ items: [DefaultResultAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveReferenceRangeSchedulesFromAudit(_ items: [DefaultResultAudit]) -> [ReferenceRangeSchedule] {
        var out: [ReferenceRangeSchedule] = []
        for item in items {
            let derived = newReferenceRangeSchedule(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceReferenceRangeSchedule(_ item: ReferenceRangeSchedule) -> Double {
        return defaultResultAuditWeight(3, active: true)
    }
}
