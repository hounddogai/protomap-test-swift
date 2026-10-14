import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalAlertTiersForProfile(_ items: [GlobalAlertTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientRoundingProfilesFromTier(_ items: [GlobalAlertTier]) -> [LenientRoundingProfile] {
        var out: [LenientRoundingProfile] = []
        for item in items {
            let derived = newLenientRoundingProfile(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveLenientRoundingProfile(_ item: LenientRoundingProfile) -> String {
        return classifyAlertTemplate(item.adjustedExposure())
    }
}
