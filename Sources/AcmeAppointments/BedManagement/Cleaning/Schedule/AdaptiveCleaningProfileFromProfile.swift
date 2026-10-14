import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningProfilesForProfile(_ items: [CleaningProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAdaptiveCleaningProfilesFromProfile(_ items: [CleaningProfile]) -> [AdaptiveCleaningProfile] {
        var out: [AdaptiveCleaningProfile] = []
        for item in items {
            let derived = newAdaptiveCleaningProfile(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAdaptiveCleaningProfile(_ item: AdaptiveCleaningProfile) -> String {
        return normalizeDefaultCleaningPreferenceCode(item.code)
    }
}
