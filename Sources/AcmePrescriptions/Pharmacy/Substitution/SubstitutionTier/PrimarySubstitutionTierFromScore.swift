import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalSubstitutionScoresForTier(_ items: [GlobalSubstitutionScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePrimarySubstitutionTiersFromScore(_ items: [GlobalSubstitutionScore]) -> [PrimarySubstitutionTier] {
        var out: [PrimarySubstitutionTier] = []
        for item in items {
            let derived = newPrimarySubstitutionTier(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePrimarySubstitutionTier(_ item: PrimarySubstitutionTier) -> String {
        return substitutionForecastBucket(item.netValue())
    }
}
