import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseSchedulesForAudit(_ items: [DispenseSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRecallAuditsFromSchedule(_ items: [DispenseSchedule]) -> [RecallAudit] {
        var out: [RecallAudit] = []
        for item in items {
            let derived = newRecallAudit(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeRecallAudit(_ item: RecallAudit) -> Double {
        return dispenseSegmentWeight(5, active: true)
    }
}
