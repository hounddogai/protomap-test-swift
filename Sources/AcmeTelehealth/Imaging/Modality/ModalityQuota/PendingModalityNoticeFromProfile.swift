import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLegacyModalityProfilesForNotice(_ items: [LegacyModalityProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingModalityNoticesFromProfile(_ items: [LegacyModalityProfile]) -> [PendingModalityNotice] {
        var out: [PendingModalityNotice] = []
        for item in items {
            let derived = newPendingModalityNotice(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computePendingModalityNotice(_ item: PendingModalityNotice) -> String {
        return classifyLegacyModalityProfile(item.measuredValue())
    }
}
