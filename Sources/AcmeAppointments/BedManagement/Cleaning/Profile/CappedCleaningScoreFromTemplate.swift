import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningTemplatesForScore(_ items: [CleaningTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedCleaningScoresFromTemplate(_ items: [CleaningTemplate]) -> [CappedCleaningScore] {
        var out: [CappedCleaningScore] = []
        for item in items {
            let derived = newCappedCleaningScore(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveCappedCleaningScore(_ item: CappedCleaningScore) -> String {
        return classifyCleaningTemplate(item.weightedLoad())
    }
}
