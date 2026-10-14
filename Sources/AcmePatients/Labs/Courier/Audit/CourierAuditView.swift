import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier audit.
    final class CourierAuditView {
        var code: String
        var title: String
        var summaryText: String
        var expiresAt: String
        var ward: String
        var acuity: String
        var maximumText: String
        var notes: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, summaryText: String, expiresAt: String, ward: String, acuity: String, maximumText: String, notes: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.summaryText = summaryText
            self.expiresAt = expiresAt
            self.ward = ward
            self.acuity = acuity
            self.maximumText = maximumText
            self.notes = notes
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toCourierAuditView(_ item: CourierAudit) -> CourierAuditView {
        return CourierAuditView(
            code: item.code,
            title: item.title,
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            expiresAt: String(item.expiresAt),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            acuity: String(item.acuity),
            maximumText: String(format: "%.2f", item.maximum),
            notes: item.notes,
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierAuditViews(_ items: [CourierAudit]) -> [CourierAuditView] {
        var views: [CourierAuditView] = []
        for item in items {
            views.append(toCourierAuditView(item))
        }
        return views
    }

    static func sumCourierAuditView(_ view: CourierAuditView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedAcuity) + parsedMaximum
    }
}
