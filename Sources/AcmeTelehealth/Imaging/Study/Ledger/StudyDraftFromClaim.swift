import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolClaimsForDraft(_ items: [CareProtocolClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveStudyDraftsFromClaim(_ items: [CareProtocolClaim]) -> [StudyDraft] {
        var out: [StudyDraft] = []
        for item in items {
            let derived = newStudyDraft(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveStudyDraft(_ item: StudyDraft) -> String {
        return normalizeCareProtocolEntryCode(item.code)
    }
}
