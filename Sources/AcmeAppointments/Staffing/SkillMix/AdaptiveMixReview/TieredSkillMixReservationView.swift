import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered skill mix reservation.
    final class TieredSkillMixReservationView {
        var codeText: String
        var title: String
        var attempts: String
        var visible: String
        var name: String
        var contactEmail: String
        var diagnosisCode: String
        var graceDays: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, title: String, attempts: String, visible: String, name: String, contactEmail: String, diagnosisCode: String, graceDays: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.attempts = attempts
            self.visible = visible
            self.name = name
            self.contactEmail = contactEmail
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSkillMixReservationView(_ item: TieredSkillMixReservation) -> TieredSkillMixReservationView {
        return TieredSkillMixReservationView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            attempts: String(item.attempts),
            visible: "\(item.visible)",
            name: item.name,
            contactEmail: item.contactEmail,
            diagnosisCode: item.diagnosisCode,
            graceDays: String(item.graceDays),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSkillMixReservationViews(_ items: [TieredSkillMixReservation]) -> [TieredSkillMixReservationView] {
        var views: [TieredSkillMixReservationView] = []
        for item in items {
            views.append(toTieredSkillMixReservationView(item))
        }
        return views
    }

    static func sumTieredSkillMixReservationView(_ view: TieredSkillMixReservationView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedAttempts) + Double(parsedGraceDays) + parsedCeiling
    }
}
