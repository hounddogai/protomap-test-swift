import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen assignment.
    final class SpecimenAssignmentView {
        var code: String
        var titleText: String
        var amountText: String
        var localeText: String
        var ward: String
        var contactEmail: String
        var bed: String
        var limit: String
        var endsAt: String
        var cost: String
        var statusLabel: String

        init(code: String, titleText: String, amountText: String, localeText: String, ward: String, contactEmail: String, bed: String, limit: String, endsAt: String, cost: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.amountText = amountText
            self.localeText = localeText
            self.ward = ward
            self.contactEmail = contactEmail
            self.bed = bed
            self.limit = limit
            self.endsAt = endsAt
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenAssignmentView(_ item: SpecimenAssignment) -> SpecimenAssignmentView {
        return SpecimenAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            localeText: Kit.Text.truncate(item.locale, limit: 80),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            contactEmail: item.contactEmail,
            bed: item.bed,
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenAssignmentViews(_ items: [SpecimenAssignment]) -> [SpecimenAssignmentView] {
        var views: [SpecimenAssignmentView] = []
        for item in items {
            views.append(toSpecimenAssignmentView(item))
        }
        return views
    }

    static func sumSpecimenAssignmentView(_ view: SpecimenAssignmentView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedAmount + Double(parsedLimit) + Double(parsedEndsAt)
    }
}
