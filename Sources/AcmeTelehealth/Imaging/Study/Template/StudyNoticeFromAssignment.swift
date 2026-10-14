import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadAssignmentsForNotice(_ items: [ReadAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStudyNoticesFromAssignment(_ items: [ReadAssignment]) -> [StudyNotice] {
        var out: [StudyNotice] = []
        for item in items {
            let derived = newStudyNotice(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleStudyNotice(_ item: StudyNotice) -> String {
        return readAssignmentBucket(item.adjustedValue())
    }
}
