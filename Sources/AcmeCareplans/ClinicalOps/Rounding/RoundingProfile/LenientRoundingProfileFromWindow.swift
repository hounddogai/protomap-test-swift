import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalHandoffWindowsForProfile(_ items: [SeasonalHandoffWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveLenientRoundingProfilesFromWindow(_ items: [SeasonalHandoffWindow]) -> [LenientRoundingProfile] {
        var out: [LenientRoundingProfile] = []
        for item in items {
            let derived = newLenientRoundingProfile(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLenientRoundingProfile(_ item: LenientRoundingProfile) -> String {
        return normalizeSeasonalHandoffWindowCode(item.code)
    }
}
