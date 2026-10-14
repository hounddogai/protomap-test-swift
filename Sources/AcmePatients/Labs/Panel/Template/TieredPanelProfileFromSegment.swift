import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalReferenceRangeSegmentsForProfile(_ items: [GlobalReferenceRangeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredPanelProfilesFromSegment(_ items: [GlobalReferenceRangeSegment]) -> [TieredPanelProfile] {
        var out: [TieredPanelProfile] = []
        for item in items {
            let derived = newTieredPanelProfile(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveTieredPanelProfile(_ item: TieredPanelProfile) -> String {
        return normalizeCappedReferenceRangeEstimateCode(item.code)
    }
}
