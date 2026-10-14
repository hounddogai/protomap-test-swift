import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolSchedulesForDigest(_ items: [CareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveScheduledCareProtocolDigestsFromSchedule(_ items: [CareProtocolSchedule]) -> [ScheduledCareProtocolDigest] {
        var out: [ScheduledCareProtocolDigest] = []
        for item in items {
            let derived = newScheduledCareProtocolDigest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleScheduledCareProtocolDigest(_ item: ScheduledCareProtocolDigest) -> String {
        return careProtocolScheduleBucket(item.weightedTotal())
    }
}
