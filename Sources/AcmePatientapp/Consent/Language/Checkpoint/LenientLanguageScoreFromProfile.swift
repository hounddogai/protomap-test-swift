import AcmePlatform
import Foundation

extension Consent {
    static func summarizePrimaryConsentFormProfilesForScore(_ items: [PrimaryConsentFormProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientLanguageScoresFromProfile(_ items: [PrimaryConsentFormProfile]) -> [LenientLanguageScore] {
        var out: [LenientLanguageScore] = []
        for item in items {
            let derived = newLenientLanguageScore(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLenientLanguageScore(_ item: LenientLanguageScore) -> Double {
        return regionalConsentFormTargetWeight(5, active: true)
    }
}
