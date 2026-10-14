import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierWindowsForMilestone(_ items: [CourierWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveDefaultCourierMilestonesFromWindow(_ items: [CourierWindow]) -> [DefaultCourierMilestone] {
        var out: [DefaultCourierMilestone] = []
        for item in items {
            let derived = newDefaultCourierMilestone(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreDefaultCourierMilestone(_ item: DefaultCourierMilestone) -> Double {
        return rollingCourierThresholdWeight(5, active: true)
    }
}
