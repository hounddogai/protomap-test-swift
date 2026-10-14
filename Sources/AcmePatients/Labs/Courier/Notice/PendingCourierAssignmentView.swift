import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending courier assignment.
    final class PendingCourierAssignmentView {
        var code: String
        var name: String
        var facility: String
        var maximum: String
        var procedureCode: String
        var discount: String
        var contactEmail: String
        var graceDaysText: String
        var ratio: String
        var refillsText: String
        var statusLabel: String

        init(code: String, name: String, facility: String, maximum: String, procedureCode: String, discount: String, contactEmail: String, graceDaysText: String, ratio: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facility = facility
            self.maximum = maximum
            self.procedureCode = procedureCode
            self.discount = discount
            self.contactEmail = contactEmail
            self.graceDaysText = graceDaysText
            self.ratio = ratio
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCourierAssignmentView(_ item: PendingCourierAssignment) -> PendingCourierAssignmentView {
        return PendingCourierAssignmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            procedureCode: item.procedureCode,
            discount: String(format: "%.2f", item.discount),
            contactEmail: item.contactEmail,
            graceDaysText: String(item.graceDays),
            ratio: String(format: "%.2f", item.ratio),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCourierAssignmentViews(_ items: [PendingCourierAssignment]) -> [PendingCourierAssignmentView] {
        var views: [PendingCourierAssignmentView] = []
        for item in items {
            views.append(toPendingCourierAssignmentView(item))
        }
        return views
    }

    static func sumPendingCourierAssignmentView(_ view: PendingCourierAssignmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMaximum + parsedDiscount + Double(parsedGraceDays)
    }
}
