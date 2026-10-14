import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackCredentialSegmentsForDraft(_ items: [FallbackCredentialSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveSkillMixDraftsFromSegment(_ items: [FallbackCredentialSegment]) -> [SkillMixDraft] {
        var out: [SkillMixDraft] = []
        for item in items {
            let derived = newSkillMixDraft(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applySkillMixDraft(_ item: SkillMixDraft) -> String {
        return normalizeCredentialExceptionCode(item.code)
    }
}
