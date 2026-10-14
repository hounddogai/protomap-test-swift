import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacySpecimenProfilesForScoreTarget(_ items: [LegacySpecimenProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDefaultResultScoresFromProfile(_ items: [LegacySpecimenProfile]) -> [DefaultResultScore] {
        var out: [DefaultResultScore] = []
        for item in items {
            let derived = newDefaultResultScore(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectDefaultResultScore(_ item: DefaultResultScore) -> String {
        return normalizeDefaultSpecimenReservationCode(item.code)
    }
}
