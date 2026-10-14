import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistBundlesForPlan(_ items: [WorklistBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveScheduledReadPlansFromBundle(_ items: [WorklistBundle]) -> [ScheduledReadPlan] {
        var out: [ScheduledReadPlan] = []
        for item in items {
            let derived = newScheduledReadPlan(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateScheduledReadPlan(_ item: ScheduledReadPlan) -> String {
        return normalizeWorklistTemplateCode(item.code)
    }
}
