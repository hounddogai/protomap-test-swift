import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalReadEstimatesForNotice(_ items: [SeasonalReadEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCareProtocolNoticesFromEstimate(_ items: [SeasonalReadEstimate]) -> [CareProtocolNotice] {
        var out: [CareProtocolNotice] = []
        for item in items {
            let derived = newCareProtocolNotice(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeCareProtocolNotice(_ item: CareProtocolNotice) -> String {
        return normalizeLenientReadMappingCode(item.code)
    }
}
