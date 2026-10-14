import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialGroupsForPreference(_ items: [CredentialGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func derivePendingSkillMixPreferencesFromGroup(_ items: [CredentialGroup]) -> [PendingSkillMixPreference] {
        var out: [PendingSkillMixPreference] = []
        for item in items {
            let derived = newPendingSkillMixPreference(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyPendingSkillMixPreference(_ item: PendingSkillMixPreference) -> String {
        return normalizeCredentialAgreementCode(item.code)
    }
}
