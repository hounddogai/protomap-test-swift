import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementAdjustmentsForCycle(_ items: [StatementAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveStatementCyclesFromAdjustment(_ items: [StatementAdjustment]) -> [StatementCycle] {
        var out: [StatementCycle] = []
        for item in items {
            let derived = newStatementCycle(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveStatementCycle(_ item: StatementCycle) -> String {
        return classifyStatementBatch(item.projectedTotal())
    }
}
