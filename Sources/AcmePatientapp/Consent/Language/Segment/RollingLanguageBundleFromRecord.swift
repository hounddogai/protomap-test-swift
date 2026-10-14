import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalRevocationRecordsForBundle(_ items: [GlobalRevocationRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingLanguageBundlesFromRecord(_ items: [GlobalRevocationRecord]) -> [RollingLanguageBundle] {
        var out: [RollingLanguageBundle] = []
        for item in items {
            let derived = newRollingLanguageBundle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingLanguageBundleExtra(_ item: RollingLanguageBundle) -> String {
        return revocationEntryBucket(item.effectiveTotal())
    }
}
