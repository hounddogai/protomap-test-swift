import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffWindowsForAdjustment(_ items: [HandoffWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRoundingAdjustmentsFromWindow(_ items: [HandoffWindow]) -> [RoundingAdjustment] {
        var out: [RoundingAdjustment] = []
        for item in items {
            let derived = newRoundingAdjustment(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRoundingAdjustment(_ item: RoundingAdjustment) -> String {
        return classifyHandoffWindow(item.projectedValue())
    }
}
