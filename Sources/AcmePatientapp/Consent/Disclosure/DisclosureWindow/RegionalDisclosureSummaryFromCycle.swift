import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageCyclesForSummary(_ items: [LanguageCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRegionalDisclosureSummariesFromCycle(_ items: [LanguageCycle]) -> [RegionalDisclosureSummary] {
        var out: [RegionalDisclosureSummary] = []
        for item in items {
            let derived = newRegionalDisclosureSummary(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalDisclosureSummary(_ item: RegionalDisclosureSummary) -> String {
        return cappedLanguagePlanBucket(item.netVolume())
    }
}
