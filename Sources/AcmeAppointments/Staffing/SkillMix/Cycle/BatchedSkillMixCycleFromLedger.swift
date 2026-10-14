import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolLedgersForCycle(_ items: [FloatPoolLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveBatchedSkillMixCyclesFromLedger(_ items: [FloatPoolLedger]) -> [BatchedSkillMixCycle] {
        var out: [BatchedSkillMixCycle] = []
        for item in items {
            let derived = newBatchedSkillMixCycle(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeBatchedSkillMixCycle(_ item: BatchedSkillMixCycle) -> Double {
        return floatPoolLedgerWeight(6, active: true)
    }
}
