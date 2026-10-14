import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeDefaultCareProtocolRecordsForBudget(_ items: [DefaultCareProtocolRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRoundingBudgetsFromRecord(_ items: [DefaultCareProtocolRecord]) -> [RoundingBudget] {
        var out: [RoundingBudget] = []
        for item in items {
            let derived = newRoundingBudget(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRoundingBudget(_ item: RoundingBudget) -> String {
        return normalizeDefaultCareProtocolRecordCode(item.code)
    }
}
