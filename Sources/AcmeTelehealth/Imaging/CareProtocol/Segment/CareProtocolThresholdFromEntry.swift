import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistEntriesForThreshold(_ items: [WorklistEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCareProtocolThresholdsFromEntry(_ items: [WorklistEntry]) -> [CareProtocolThreshold] {
        var out: [CareProtocolThreshold] = []
        for item in items {
            let derived = newCareProtocolThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCareProtocolThreshold(_ item: CareProtocolThreshold) -> String {
        return normalizeWorklistEstimateCode(item.code)
    }
}
