import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLenientLanguageProfilesForSnapshot(_ items: [LenientLanguageProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLenientConsentFormSnapshotsFromProfile(_ items: [LenientLanguageProfile]) -> [LenientConsentFormSnapshot] {
        var out: [LenientConsentFormSnapshot] = []
        for item in items {
            let derived = newLenientConsentFormSnapshot(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLenientConsentFormSnapshot(_ item: LenientConsentFormSnapshot) -> Double {
        return lenientLanguageProfileWeight(6, active: true)
    }
}
