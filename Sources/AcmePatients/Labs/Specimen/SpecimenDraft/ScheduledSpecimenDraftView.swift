import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled specimen draft.
    final class ScheduledSpecimenDraftView {
        var code: String
        var titleText: String
        var contactEmail: String
        var sequenceText: String
        var facility: String
        var statusLabel: String

        init(code: String, titleText: String, contactEmail: String, sequenceText: String, facility: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.contactEmail = contactEmail
            self.sequenceText = sequenceText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledSpecimenDraftView(_ item: ScheduledSpecimenDraft) -> ScheduledSpecimenDraftView {
        return ScheduledSpecimenDraftView(
            code: item.code,
            titleText: item.title,
            contactEmail: item.contactEmail,
            sequenceText: String(item.sequence),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledSpecimenDraftViews(_ items: [ScheduledSpecimenDraft]) -> [ScheduledSpecimenDraftView] {
        var views: [ScheduledSpecimenDraftView] = []
        for item in items {
            views.append(toScheduledSpecimenDraftView(item))
        }
        return views
    }

    static func sumScheduledSpecimenDraftView(_ view: ScheduledSpecimenDraftView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
