import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseMetricsForAssignment(_ items: [DispenseMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveFormularyAssignmentsFromMetric(_ items: [DispenseMetric]) -> [FormularyAssignment] {
        var out: [FormularyAssignment] = []
        for item in items {
            let derived = newFormularyAssignment(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyFormularyAssignment(_ item: FormularyAssignment) -> String {
        return classifyDispenseSchedule(item.projectedLoad())
    }
}
