import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryRecallProfilesForVariance(_ items: [PrimaryRecallProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveSubstitutionVariancesFromProfile(_ items: [PrimaryRecallProfile]) -> [SubstitutionVariance] {
        var out: [SubstitutionVariance] = []
        for item in items {
            let derived = newSubstitutionVariance(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeSubstitutionVariance(_ item: SubstitutionVariance) -> String {
        return classifyRollingRecallBaseline(item.netTotal())
    }
}
