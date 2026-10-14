import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveCleaningBudgetsForPolicy(_ items: [AdaptiveCleaningBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRegionalIsolationPoliciesFromBudget(_ items: [AdaptiveCleaningBudget]) -> [RegionalIsolationPolicy] {
        var out: [RegionalIsolationPolicy] = []
        for item in items {
            let derived = newRegionalIsolationPolicy(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankRegionalIsolationPolicy(_ item: RegionalIsolationPolicy) -> String {
        return classifyAdaptiveCleaningBudget(item.projectedVolume())
    }

    static func summarizeGlobalDischargePlanBudgetsForPolicy(_ items: [GlobalDischargePlanBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRegionalIsolationPoliciesFromBudgetExtra(_ items: [GlobalDischargePlanBudget]) -> [RegionalIsolationPolicy] {
        var out: [RegionalIsolationPolicy] = []
        for item in items {
            let derived = newRegionalIsolationPolicy(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalIsolationPolicy(_ item: RegionalIsolationPolicy) -> Double {
        return globalDischargePlanBudgetWeight(3, active: true)
    }
}
