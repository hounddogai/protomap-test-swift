import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictProxyManifestsForAdjustment(_ items: [StrictProxyManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWitnessAdjustmentsFromManifest(_ items: [StrictProxyManifest]) -> [WitnessAdjustment] {
        var out: [WitnessAdjustment] = []
        for item in items {
            let derived = newWitnessAdjustment(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileWitnessAdjustment(_ item: WitnessAdjustment) -> String {
        return classifyProxyLedger(item.adjustedValue())
    }
}
