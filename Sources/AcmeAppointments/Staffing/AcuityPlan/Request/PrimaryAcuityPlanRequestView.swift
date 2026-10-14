import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary acuity plan request.
    final class PrimaryAcuityPlanRequestView {
        var code: String
        var name: String
        var limitText: String
        var durationMinutes: String
        var patientRefText: String
        var expiresAt: String
        var active: String
        var contactEmail: String
        var visibleText: String
        var endsAt: String
        var priority: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, durationMinutes: String, patientRefText: String, expiresAt: String, active: String, contactEmail: String, visibleText: String, endsAt: String, priority: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.durationMinutes = durationMinutes
            self.patientRefText = patientRefText
            self.expiresAt = expiresAt
            self.active = active
            self.contactEmail = contactEmail
            self.visibleText = visibleText
            self.endsAt = endsAt
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryAcuityPlanRequestView(_ item: PrimaryAcuityPlanRequest) -> PrimaryAcuityPlanRequestView {
        return PrimaryAcuityPlanRequestView(
            code: item.code,
            name: item.name,
            limitText: String(item.limit),
            durationMinutes: String(item.durationMinutes),
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 80),
            expiresAt: String(item.expiresAt),
            active: "\(item.active)",
            contactEmail: item.contactEmail,
            visibleText: "\(item.visible)",
            endsAt: String(item.endsAt),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryAcuityPlanRequestViews(_ items: [PrimaryAcuityPlanRequest]) -> [PrimaryAcuityPlanRequestView] {
        var views: [PrimaryAcuityPlanRequestView] = []
        for item in items {
            views.append(toPrimaryAcuityPlanRequestView(item))
        }
        return views
    }

    static func sumPrimaryAcuityPlanRequestView(_ view: PrimaryAcuityPlanRequestView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedLimit) + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
