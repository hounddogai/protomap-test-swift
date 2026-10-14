import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyBaselinesForPlan(_ items: [StudyBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveReadPlansFromBaseline(_ items: [StudyBaseline]) -> [ReadPlan] {
        var out: [ReadPlan] = []
        for item in items {
            let derived = newReadPlan(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveReadPlan(_ item: ReadPlan) -> String {
        return normalizeStudyBaselineCode(item.code)
    }
}
