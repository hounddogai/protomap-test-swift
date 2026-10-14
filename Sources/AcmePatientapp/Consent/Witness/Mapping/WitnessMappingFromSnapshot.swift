import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageSnapshotsForMapping(_ items: [LanguageSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWitnessMappingsFromSnapshot(_ items: [LanguageSnapshot]) -> [WitnessMapping] {
        var out: [WitnessMapping] = []
        for item in items {
            let derived = newWitnessMapping(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyWitnessMapping(_ item: WitnessMapping) -> Double {
        return languageWindowWeight(3, active: true)
    }
}
