import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityReviewsForGroup(_ items: [ModalityReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveWorklistGroupsFromReview(_ items: [ModalityReview]) -> [WorklistGroup] {
        var out: [WorklistGroup] = []
        for item in items {
            let derived = newWorklistGroup(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveWorklistGroup(_ item: WorklistGroup) -> String {
        return normalizeTieredModalityProfileCode(item.code)
    }
}
