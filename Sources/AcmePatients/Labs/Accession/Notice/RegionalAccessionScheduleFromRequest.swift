import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredResultRequestsForSchedule(_ items: [TieredResultRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveRegionalAccessionSchedulesFromRequest(_ items: [TieredResultRequest]) -> [RegionalAccessionSchedule] {
        var out: [RegionalAccessionSchedule] = []
        for item in items {
            let derived = newRegionalAccessionSchedule(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRegionalAccessionSchedule(_ item: RegionalAccessionSchedule) -> String {
        return tieredResultRequestBucket(item.netLoad())
    }
}
