import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultThresholdsForAssignment(_ items: [ResultThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveReferenceRangeAssignmentsFromThreshold(_ items: [ResultThreshold]) -> [ReferenceRangeAssignment] {
        var out: [ReferenceRangeAssignment] = []
        for item in items {
            let derived = newReferenceRangeAssignment(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeReferenceRangeAssignment(_ item: ReferenceRangeAssignment) -> String {
        return classifyResultSchedule(item.weightedValue())
    }
}
