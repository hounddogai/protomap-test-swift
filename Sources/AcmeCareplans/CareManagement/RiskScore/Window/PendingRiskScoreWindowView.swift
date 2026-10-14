import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending risk score window.
    final class PendingRiskScoreWindowView {
        var codeText: String
        var label: String
        var graceDays: String
        var refills: String
        var contactEmail: String
        var patientRef: String
        var visitMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, graceDays: String, refills: String, contactEmail: String, patientRef: String, visitMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDays = graceDays
            self.refills = refills
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRiskScoreWindowView(_ item: PendingRiskScoreWindow) -> PendingRiskScoreWindowView {
        return PendingRiskScoreWindowView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            graceDays: String(item.graceDays),
            refills: String(item.refills),
            contactEmail: item.contactEmail,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRiskScoreWindowViews(_ items: [PendingRiskScoreWindow]) -> [PendingRiskScoreWindowView] {
        var views: [PendingRiskScoreWindowView] = []
        for item in items {
            views.append(toPendingRiskScoreWindowView(item))
        }
        return views
    }

    static func sumPendingRiskScoreWindowView(_ view: PendingRiskScoreWindowView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRefills) + Double(parsedVisitMinutes)
    }
}
