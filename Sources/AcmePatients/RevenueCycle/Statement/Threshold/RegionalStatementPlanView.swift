import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional statement plan.
    final class RegionalStatementPlanView {
        var code: String
        var titleText: String
        var label: String
        var expiresAt: String
        var minimum: String
        var contactEmail: String
        var acuity: String
        var notesText: String
        var specialtyText: String
        var statusLabel: String

        init(code: String, titleText: String, label: String, expiresAt: String, minimum: String, contactEmail: String, acuity: String, notesText: String, specialtyText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.label = label
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.notesText = notesText
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStatementPlanView(_ item: RegionalStatementPlan) -> RegionalStatementPlanView {
        return RegionalStatementPlanView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            label: item.label,
            expiresAt: String(item.expiresAt),
            minimum: String(format: "%.2f", item.minimum),
            contactEmail: item.contactEmail,
            acuity: String(item.acuity),
            notesText: item.notes,
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStatementPlanViews(_ items: [RegionalStatementPlan]) -> [RegionalStatementPlanView] {
        var views: [RegionalStatementPlanView] = []
        for item in items {
            views.append(toRegionalStatementPlanView(item))
        }
        return views
    }

    static func sumRegionalStatementPlanView(_ view: RegionalStatementPlanView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedExpiresAt) + parsedMinimum + Double(parsedAcuity)
    }
}
