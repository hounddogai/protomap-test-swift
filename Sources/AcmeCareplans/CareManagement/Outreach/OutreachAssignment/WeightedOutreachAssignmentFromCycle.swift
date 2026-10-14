import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramCyclesForAssignment(_ items: [ProgramCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedOutreachAssignmentsFromCycle(_ items: [ProgramCycle]) -> [WeightedOutreachAssignment] {
        var out: [WeightedOutreachAssignment] = []
        for item in items {
            let derived = newWeightedOutreachAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankWeightedOutreachAssignment(_ item: WeightedOutreachAssignment) -> String {
        return lenientProgramWindowBucket(item.effectiveExposure())
    }
}
