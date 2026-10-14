import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualSpecimenAgreementsForPreference(_ items: [ManualSpecimenAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveScheduledAccessionPreferencesFromAgreement(_ items: [ManualSpecimenAgreement]) -> [ScheduledAccessionPreference] {
        var out: [ScheduledAccessionPreference] = []
        for item in items {
            let derived = newScheduledAccessionPreference(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreScheduledAccessionPreference(_ item: ScheduledAccessionPreference) -> String {
        return specimenDigestBucket(item.weightedLoad())
    }
}
