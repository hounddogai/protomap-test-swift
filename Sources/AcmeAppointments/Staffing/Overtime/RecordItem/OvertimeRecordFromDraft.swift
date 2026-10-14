import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanDraftsForRecord(_ items: [AcuityPlanDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOvertimeRecordsFromDraft(_ items: [AcuityPlanDraft]) -> [OvertimeRecord] {
        var out: [OvertimeRecord] = []
        for item in items {
            let derived = newOvertimeRecord(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveOvertimeRecord(_ item: OvertimeRecord) -> String {
        return classifyAdaptiveAcuityPlanEstimate(item.measuredValue())
    }
}
