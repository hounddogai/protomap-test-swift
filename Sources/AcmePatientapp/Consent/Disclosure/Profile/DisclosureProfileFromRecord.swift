import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormRecordsForProfile(_ items: [ConsentFormRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDisclosureProfilesFromRecord(_ items: [ConsentFormRecord]) -> [DisclosureProfile] {
        var out: [DisclosureProfile] = []
        for item in items {
            let derived = newDisclosureProfile(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectDisclosureProfile(_ item: DisclosureProfile) -> String {
        return consentFormRecordBucket(item.netVolume())
    }
}
