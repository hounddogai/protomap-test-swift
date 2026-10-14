import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling denial audit.
    final class RollingDenialAuditView {
        var code: String
        var label: String
        var discount: String
        var active: String
        var channelText: String
        var currency: String
        var visitMinutesText: String
        var contactEmail: String
        var clinicianID: String
        var reviewer: String
        var statusLabel: String

        init(code: String, label: String, discount: String, active: String, channelText: String, currency: String, visitMinutesText: String, contactEmail: String, clinicianID: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.active = active
            self.channelText = channelText
            self.currency = currency
            self.visitMinutesText = visitMinutesText
            self.contactEmail = contactEmail
            self.clinicianID = clinicianID
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDenialAuditView(_ item: RollingDenialAudit) -> RollingDenialAuditView {
        return RollingDenialAuditView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            discount: String(format: "%.2f", item.discount),
            active: "\(item.active)",
            channelText: Kit.Text.truncate(item.channel, limit: 120),
            currency: item.currency,
            visitMinutesText: String(item.visitMinutes),
            contactEmail: item.contactEmail,
            clinicianID: item.clinicianID,
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDenialAuditViews(_ items: [RollingDenialAudit]) -> [RollingDenialAuditView] {
        var views: [RollingDenialAuditView] = []
        for item in items {
            views.append(toRollingDenialAuditView(item))
        }
        return views
    }

    static func sumRollingDenialAuditView(_ view: RollingDenialAuditView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedDiscount + Double(parsedVisitMinutes)
    }
}
