import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingDispenseRulesForDigest(_ items: [RollingDispenseRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLenientSubstitutionDigestsFromRule(_ items: [RollingDispenseRule]) -> [LenientSubstitutionDigest] {
        var out: [LenientSubstitutionDigest] = []
        for item in items {
            let derived = newLenientSubstitutionDigest(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceLenientSubstitutionDigest(_ item: LenientSubstitutionDigest) -> String {
        return classifyRollingDispenseRule(item.measuredValue())
    }
}
