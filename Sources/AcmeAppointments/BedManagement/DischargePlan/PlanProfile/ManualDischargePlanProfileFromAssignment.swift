import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRollingIsolationAssignmentsForProfile(_ items: [RollingIsolationAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveManualDischargePlanProfilesFromAssignment(_ items: [RollingIsolationAssignment]) -> [ManualDischargePlanProfile] {
        var out: [ManualDischargePlanProfile] = []
        for item in items {
            let derived = newManualDischargePlanProfile(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankManualDischargePlanProfile(_ item: ManualDischargePlanProfile) -> String {
        return classifyIsolationForecast(item.effectiveValue())
    }
}
