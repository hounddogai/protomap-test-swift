import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialQuotasForAssignment(_ items: [CredentialQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveLenientSkillMixAssignmentsFromQuota(_ items: [CredentialQuota]) -> [LenientSkillMixAssignment] {
        var out: [LenientSkillMixAssignment] = []
        for item in items {
            let derived = newLenientSkillMixAssignment(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankLenientSkillMixAssignment(_ item: LenientSkillMixAssignment) -> String {
        return normalizeCredentialQuotaCode(item.code)
    }
}
