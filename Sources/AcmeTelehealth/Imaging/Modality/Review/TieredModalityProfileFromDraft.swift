import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadDraftsForProfile(_ items: [ReadDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredModalityProfilesFromDraft(_ items: [ReadDraft]) -> [TieredModalityProfile] {
        var out: [TieredModalityProfile] = []
        for item in items {
            let derived = newTieredModalityProfile(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveTieredModalityProfile(_ item: TieredModalityProfile) -> String {
        return readThresholdBucket(item.netExposure())
    }
}
