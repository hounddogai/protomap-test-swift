import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default remittance audit.
    final class DefaultRemittanceAuditView {
        var code: String
        var title: String
        var visitMinutesText: String
        var floorValue: String
        var visibleText: String
        var statusLabel: String

        init(code: String, title: String, visitMinutesText: String, floorValue: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.floorValue = floorValue
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRemittanceAuditView(_ item: DefaultRemittanceAudit) -> DefaultRemittanceAuditView {
        return DefaultRemittanceAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            floorValue: String(format: "%.2f", item.floorValue),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRemittanceAuditViews(_ items: [DefaultRemittanceAudit]) -> [DefaultRemittanceAuditView] {
        var views: [DefaultRemittanceAuditView] = []
        for item in items {
            views.append(toDefaultRemittanceAuditView(item))
        }
        return views
    }

    static func sumDefaultRemittanceAuditView(_ view: DefaultRemittanceAuditView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedVisitMinutes) + parsedFloorValue
    }
}
