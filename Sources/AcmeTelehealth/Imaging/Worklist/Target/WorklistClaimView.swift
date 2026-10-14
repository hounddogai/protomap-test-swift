import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist claim.
    final class WorklistClaimView {
        var code: String
        var nameText: String
        var durationMinutesText: String
        var acuity: String
        var contactEmailText: String
        var procedureCode: String
        var visible: String
        var pinned: String
        var attempts: String
        var statusLabel: String

        init(code: String, nameText: String, durationMinutesText: String, acuity: String, contactEmailText: String, procedureCode: String, visible: String, pinned: String, attempts: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.durationMinutesText = durationMinutesText
            self.acuity = acuity
            self.contactEmailText = contactEmailText
            self.procedureCode = procedureCode
            self.visible = visible
            self.pinned = pinned
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistClaimView(_ item: WorklistClaim) -> WorklistClaimView {
        return WorklistClaimView(
            code: item.code,
            nameText: item.name,
            durationMinutesText: String(item.durationMinutes),
            acuity: String(item.acuity),
            contactEmailText: item.contactEmail,
            procedureCode: item.procedureCode,
            visible: "\(item.visible)",
            pinned: "\(item.pinned)",
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistClaimViews(_ items: [WorklistClaim]) -> [WorklistClaimView] {
        var views: [WorklistClaimView] = []
        for item in items {
            views.append(toWorklistClaimView(item))
        }
        return views
    }

    static func sumWorklistClaimView(_ view: WorklistClaimView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedAcuity) + Double(parsedAttempts)
    }
}
