import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackAccessionReservationsForPlan(_ items: [FallbackAccessionReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCourierPlansFromReservation(_ items: [FallbackAccessionReservation]) -> [CourierPlan] {
        var out: [CourierPlan] = []
        for item in items {
            let derived = newCourierPlan(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCourierPlan(_ item: CourierPlan) -> String {
        return accessionRollupBucket(item.weightedVolume())
    }
}
