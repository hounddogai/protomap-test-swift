import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalPanelLedgersForReview(_ items: [GlobalPanelLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalSpecimenReviewsFromLedger(_ items: [GlobalPanelLedger]) -> [GlobalSpecimenReview] {
        var out: [GlobalSpecimenReview] = []
        for item in items {
            let derived = newGlobalSpecimenReview(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeGlobalSpecimenReview(_ item: GlobalSpecimenReview) -> String {
        return regionalPanelPreferenceBucket(item.measuredValue())
    }
}
