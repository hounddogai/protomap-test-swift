import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionThresholdsForAssignment(_ items: [AccessionThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAccessionAssignmentsFromThreshold(_ items: [AccessionThreshold]) -> [AccessionAssignment] {
        var out: [AccessionAssignment] = []
        for item in items {
            let derived = newAccessionAssignment(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAccessionAssignment(_ item: AccessionAssignment) -> String {
        return accessionDraftBucket(item.weightedValue())
    }
}
