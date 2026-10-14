import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled inventory audit.
    final class ScheduledInventoryAuditView {
        var code: String
        var title: String
        var visitMinutes: String
        var acuity: String
        var minimumText: String
        var updatedAt: String
        var segment: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, acuity: String, minimumText: String, updatedAt: String, segment: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.acuity = acuity
            self.minimumText = minimumText
            self.updatedAt = updatedAt
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledInventoryAuditView(_ item: ScheduledInventoryAudit) -> ScheduledInventoryAuditView {
        return ScheduledInventoryAuditView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            acuity: String(item.acuity),
            minimumText: String(format: "%.2f", item.minimum),
            updatedAt: String(item.updatedAt),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledInventoryAuditViews(_ items: [ScheduledInventoryAudit]) -> [ScheduledInventoryAuditView] {
        var views: [ScheduledInventoryAuditView] = []
        for item in items {
            views.append(toScheduledInventoryAuditView(item))
        }
        return views
    }

    static func sumScheduledInventoryAuditView(_ view: ScheduledInventoryAuditView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedAcuity) + parsedMinimum
    }
}
