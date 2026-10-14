import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationEstimatesForDraft(_ items: [RevocationEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRegionalWitnessDraftsFromEstimate(_ items: [RevocationEstimate]) -> [RegionalWitnessDraft] {
        var out: [RegionalWitnessDraft] = []
        for item in items {
            let derived = newRegionalWitnessDraft(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRegionalWitnessDraft(_ item: RegionalWitnessDraft) -> String {
        return normalizeRevocationEstimateCode(item.code)
    }
}
