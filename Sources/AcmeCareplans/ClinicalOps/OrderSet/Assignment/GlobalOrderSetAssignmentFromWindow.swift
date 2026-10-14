import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskWindowsForAssignment(_ items: [TaskWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveGlobalOrderSetAssignmentsFromWindow(_ items: [TaskWindow]) -> [GlobalOrderSetAssignment] {
        var out: [GlobalOrderSetAssignment] = []
        for item in items {
            let derived = newGlobalOrderSetAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileGlobalOrderSetAssignment(_ item: GlobalOrderSetAssignment) -> Double {
        return weightedTaskManifestWeight(8, active: true)
    }
}
