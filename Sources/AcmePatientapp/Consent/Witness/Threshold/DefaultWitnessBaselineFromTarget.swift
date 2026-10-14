import AcmePlatform
import Foundation

extension Consent {
    static func summarizeAdaptiveRevocationTargetsForBaseline(_ items: [AdaptiveRevocationTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDefaultWitnessBaselinesFromTarget(_ items: [AdaptiveRevocationTarget]) -> [DefaultWitnessBaseline] {
        var out: [DefaultWitnessBaseline] = []
        for item in items {
            let derived = newDefaultWitnessBaseline(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankDefaultWitnessBaseline(_ item: DefaultWitnessBaseline) -> Double {
        return revocationEntryWeight(9, active: true)
    }
}
