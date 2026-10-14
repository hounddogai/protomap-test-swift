import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessSchedulesForDigest(_ items: [WitnessSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWitnessDigestsFromSchedule(_ items: [WitnessSchedule]) -> [WitnessDigest] {
        var out: [WitnessDigest] = []
        for item in items {
            let derived = newWitnessDigest(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitWitnessDigest(_ item: WitnessDigest) -> String {
        return normalizeDefaultWitnessPreferenceCode(item.code)
    }
}
