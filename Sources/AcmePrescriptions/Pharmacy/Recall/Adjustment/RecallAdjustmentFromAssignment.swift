import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedRecallAssignmentsForAdjustment(_ items: [CappedRecallAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRecallAdjustmentsFromAssignment(_ items: [CappedRecallAssignment]) -> [RecallAdjustment] {
        var out: [RecallAdjustment] = []
        for item in items {
            let derived = newRecallAdjustment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRecallAdjustment(_ item: RecallAdjustment) -> String {
        return classifyRegionalRecallRequest(item.measuredValue())
    }
}
