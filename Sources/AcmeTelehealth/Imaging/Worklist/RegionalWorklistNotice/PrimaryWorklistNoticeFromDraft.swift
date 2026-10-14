import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientStudyDraftsForNotice(_ items: [LenientStudyDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePrimaryWorklistNoticesFromDraft(_ items: [LenientStudyDraft]) -> [PrimaryWorklistNotice] {
        var out: [PrimaryWorklistNotice] = []
        for item in items {
            let derived = newPrimaryWorklistNotice(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePrimaryWorklistNotice(_ item: PrimaryWorklistNotice) -> String {
        return normalizeStudyReservationCode(item.code)
    }
}
