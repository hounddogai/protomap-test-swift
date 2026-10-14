import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormDigestsForCheckpoint(_ items: [ConsentFormDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLanguageCheckpointsFromDigest(_ items: [ConsentFormDigest]) -> [LanguageCheckpoint] {
        var out: [LanguageCheckpoint] = []
        for item in items {
            let derived = newLanguageCheckpoint(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeLanguageCheckpoint(_ item: LanguageCheckpoint) -> String {
        return consentFormBundleBucket(item.adjustedTotal())
    }
}
