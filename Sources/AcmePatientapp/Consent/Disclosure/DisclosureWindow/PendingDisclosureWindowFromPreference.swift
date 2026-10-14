import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessPreferencesForWindow(_ items: [WitnessPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func derivePendingDisclosureWindowsFromPreference(_ items: [WitnessPreference]) -> [PendingDisclosureWindow] {
        var out: [PendingDisclosureWindow] = []
        for item in items {
            let derived = newPendingDisclosureWindow(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePendingDisclosureWindow(_ item: PendingDisclosureWindow) -> Double {
        return witnessManifestWeight(8, active: true)
    }
}
