import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacyShiftRollupsForEntry(_ items: [LegacyShiftRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRegionalOvertimeEntriesFromRollup(_ items: [LegacyShiftRollup]) -> [RegionalOvertimeEntry] {
        var out: [RegionalOvertimeEntry] = []
        for item in items {
            let derived = newRegionalOvertimeEntry(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRegionalOvertimeEntry(_ item: RegionalOvertimeEntry) -> String {
        return classifyFallbackShiftMapping(item.projectedTotal())
    }
}
