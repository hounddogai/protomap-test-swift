import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramEstimatesForCycle(_ items: [ProgramEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveScheduledOutreachCyclesFromEstimate(_ items: [ProgramEstimate]) -> [ScheduledOutreachCycle] {
        var out: [ScheduledOutreachCycle] = []
        for item in items {
            let derived = newScheduledOutreachCycle(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignScheduledOutreachCycle(_ item: ScheduledOutreachCycle) -> String {
        return normalizeProgramEstimateCode(item.code)
    }
}
