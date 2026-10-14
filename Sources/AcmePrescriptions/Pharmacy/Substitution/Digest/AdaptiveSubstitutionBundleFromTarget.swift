import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseTargetsForBundle(_ items: [DispenseTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAdaptiveSubstitutionBundlesFromTarget(_ items: [DispenseTarget]) -> [AdaptiveSubstitutionBundle] {
        var out: [AdaptiveSubstitutionBundle] = []
        for item in items {
            let derived = newAdaptiveSubstitutionBundle(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectAdaptiveSubstitutionBundle(_ item: AdaptiveSubstitutionBundle) -> String {
        return dispenseAuditBucket(item.measuredValue())
    }
}
