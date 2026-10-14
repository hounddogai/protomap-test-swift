import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityScoresForRecord(_ items: [EligibilityScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRegionalEligibilityRecordsFromScore(_ items: [EligibilityScore]) -> [RegionalEligibilityRecord] {
        var out: [RegionalEligibilityRecord] = []
        for item in items {
            let derived = newRegionalEligibilityRecord(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitRegionalEligibilityRecord(_ item: RegionalEligibilityRecord) -> String {
        return classifyEligibilityException(item.effectiveVolume())
    }

    static func summarizeRegionalNetworkScoresForRecord(_ items: [RegionalNetworkScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalEligibilityRecordsFromScoreExtra(_ items: [RegionalNetworkScore]) -> [RegionalEligibilityRecord] {
        var out: [RegionalEligibilityRecord] = []
        for item in items {
            let derived = newRegionalEligibilityRecord(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRegionalEligibilityRecord(_ item: RegionalEligibilityRecord) -> Double {
        return manualNetworkPlanWeight(2, active: true)
    }
}
