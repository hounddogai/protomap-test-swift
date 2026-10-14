import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling witness assignment.
    final class RollingWitnessAssignmentView {
        var code: String
        var title: String
        var diagnosisCode: String
        var quantityText: String
        var attemptsText: String
        var localeText: String
        var expiresAt: String
        var batchSize: String
        var phone: String
        var limit: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, title: String, diagnosisCode: String, quantityText: String, attemptsText: String, localeText: String, expiresAt: String, batchSize: String, phone: String, limit: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.quantityText = quantityText
            self.attemptsText = attemptsText
            self.localeText = localeText
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.phone = phone
            self.limit = limit
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingWitnessAssignmentView(_ item: RollingWitnessAssignment) -> RollingWitnessAssignmentView {
        return RollingWitnessAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            quantityText: String(item.quantity),
            attemptsText: String(item.attempts),
            localeText: item.locale,
            expiresAt: String(item.expiresAt),
            batchSize: String(item.batchSize),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            limit: String(item.limit),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingWitnessAssignmentViews(_ items: [RollingWitnessAssignment]) -> [RollingWitnessAssignmentView] {
        var views: [RollingWitnessAssignmentView] = []
        for item in items {
            views.append(toRollingWitnessAssignmentView(item))
        }
        return views
    }

    static func sumRollingWitnessAssignmentView(_ view: RollingWitnessAssignmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedQuantity) + Double(parsedAttempts) + Double(parsedExpiresAt)
    }
}
