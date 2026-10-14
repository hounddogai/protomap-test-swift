import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeProgramAuditsForBatch(_ items: [ProgramAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDefaultRiskScoreBatchesFromAudit(_ items: [ProgramAudit]) -> [DefaultRiskScoreBatch] {
        var out: [DefaultRiskScoreBatch] = []
        for item in items {
            let derived = newDefaultRiskScoreBatch(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchDefaultRiskScoreBatch(_ item: DefaultRiskScoreBatch) -> String {
        return classifyBatchedProgramWindow(item.measuredValue())
    }
}
