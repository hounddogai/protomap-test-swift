import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDefaultLanguageAllocationsForBundle(_ items: [DefaultLanguageAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveConsentFormBundlesFromAllocation(_ items: [DefaultLanguageAllocation]) -> [ConsentFormBundle] {
        var out: [ConsentFormBundle] = []
        for item in items {
            let derived = newConsentFormBundle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveConsentFormBundle(_ item: ConsentFormBundle) -> String {
        return languageEntryBucket(item.effectiveLoad())
    }
}
