import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientProgramBaselinesForEntry(_ items: [LenientProgramBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveTieredRiskScoreEntriesFromBaseline(_ items: [LenientProgramBaseline]) -> [TieredRiskScoreEntry] {
        var out: [TieredRiskScoreEntry] = []
        for item in items {
            let derived = newTieredRiskScoreEntry(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateTieredRiskScoreEntry(_ item: TieredRiskScoreEntry) -> String {
        return classifyAdaptiveProgramException(item.weightedVolume())
    }
}
