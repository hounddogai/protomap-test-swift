import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalSpecimenRulesForScore(_ items: [GlobalSpecimenRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveStrictReferenceRangeScoresFromRule(_ items: [GlobalSpecimenRule]) -> [StrictReferenceRangeScore] {
        var out: [StrictReferenceRangeScore] = []
        for item in items {
            let derived = newStrictReferenceRangeScore(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStrictReferenceRangeScore(_ item: StrictReferenceRangeScore) -> String {
        return rollingSpecimenEntryBucket(item.adjustedVolume())
    }
}
