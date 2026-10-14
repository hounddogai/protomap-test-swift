import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackOutreachRulesForDigest(_ items: [FallbackOutreachRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveProgramDigestsFromRule(_ items: [FallbackOutreachRule]) -> [ProgramDigest] {
        var out: [ProgramDigest] = []
        for item in items {
            let derived = newProgramDigest(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planProgramDigest(_ item: ProgramDigest) -> Double {
        return fallbackOutreachRuleWeight(9, active: true)
    }
}
