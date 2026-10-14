import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual reference range assignment.
    final class ManualReferenceRangeAssignmentView {
        var code: String
        var nameText: String
        var currency: String
        var startsAtText: String
        var maximum: String
        var contactEmail: String
        var visitMinutesText: String
        var revisionText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, nameText: String, currency: String, startsAtText: String, maximum: String, contactEmail: String, visitMinutesText: String, revisionText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.currency = currency
            self.startsAtText = startsAtText
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.visitMinutesText = visitMinutesText
            self.revisionText = revisionText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toManualReferenceRangeAssignmentView(_ item: ManualReferenceRangeAssignment) -> ManualReferenceRangeAssignmentView {
        return ManualReferenceRangeAssignmentView(
            code: item.code,
            nameText: item.name,
            currency: item.currency,
            startsAtText: String(item.startsAt),
            maximum: String(format: "%.2f", item.maximum),
            contactEmail: item.contactEmail,
            visitMinutesText: String(item.visitMinutes),
            revisionText: String(item.revision),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualReferenceRangeAssignmentViews(_ items: [ManualReferenceRangeAssignment]) -> [ManualReferenceRangeAssignmentView] {
        var views: [ManualReferenceRangeAssignmentView] = []
        for item in items {
            views.append(toManualReferenceRangeAssignmentView(item))
        }
        return views
    }

    static func sumManualReferenceRangeAssignmentView(_ view: ManualReferenceRangeAssignmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedStartsAt) + parsedMaximum + Double(parsedVisitMinutes)
    }
}
