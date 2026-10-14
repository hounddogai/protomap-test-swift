import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedReadDigestsForDraft(_ items: [CappedReadDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRegionalStudyDraftsFromDigest(_ items: [CappedReadDigest]) -> [RegionalStudyDraft] {
        var out: [RegionalStudyDraft] = []
        for item in items {
            let derived = newRegionalStudyDraft(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalStudyDraft(_ item: RegionalStudyDraft) -> String {
        return normalizeCappedReadDigestCode(item.code)
    }
}
