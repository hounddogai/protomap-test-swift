import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped panel audit.
    final class CappedPanelAuditView {
        var code: String
        var nameText: String
        var labelText: String
        var archivedText: String
        var discount: String
        var ownerID: String
        var visibleText: String
        var statusLabel: String

        init(code: String, nameText: String, labelText: String, archivedText: String, discount: String, ownerID: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.labelText = labelText
            self.archivedText = archivedText
            self.discount = discount
            self.ownerID = ownerID
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedPanelAuditView(_ item: CappedPanelAudit) -> CappedPanelAuditView {
        return CappedPanelAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            labelText: item.label,
            archivedText: "\(item.archived)",
            discount: String(format: "%.2f", item.discount),
            ownerID: item.ownerID,
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedPanelAuditViews(_ items: [CappedPanelAudit]) -> [CappedPanelAuditView] {
        var views: [CappedPanelAuditView] = []
        for item in items {
            views.append(toCappedPanelAuditView(item))
        }
        return views
    }

    static func sumCappedPanelAuditView(_ view: CappedPanelAuditView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedDiscount
    }
}
