import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeDefaultOvertimeDigestsForMilestone(_ items: [DefaultOvertimeDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func derivePrimaryFloatPoolMilestonesFromDigest(_ items: [DefaultOvertimeDigest]) -> [PrimaryFloatPoolMilestone] {
        var out: [PrimaryFloatPoolMilestone] = []
        for item in items {
            let derived = newPrimaryFloatPoolMilestone(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPrimaryFloatPoolMilestone(_ item: PrimaryFloatPoolMilestone) -> Double {
        return defaultOvertimeDigestWeight(3, active: true)
    }
}
