import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusManifestsForPreference(_ items: [CensusManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingIsolationPreferencesFromManifest(_ items: [CensusManifest]) -> [RollingIsolationPreference] {
        var out: [RollingIsolationPreference] = []
        for item in items {
            let derived = newRollingIsolationPreference(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectRollingIsolationPreference(_ item: RollingIsolationPreference) -> String {
        return normalizeGlobalCensusLedgerCode(item.code)
    }
}
