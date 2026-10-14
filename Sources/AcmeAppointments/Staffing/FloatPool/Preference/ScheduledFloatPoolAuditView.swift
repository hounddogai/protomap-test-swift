import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled float pool audit.
    final class ScheduledFloatPoolAuditView {
        var code: String
        var labelText: String
        var payer: String
        var channelText: String
        var nameText: String
        var quantityText: String
        var statusLabel: String

        init(code: String, labelText: String, payer: String, channelText: String, nameText: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.payer = payer
            self.channelText = channelText
            self.nameText = nameText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFloatPoolAuditView(_ item: ScheduledFloatPoolAudit) -> ScheduledFloatPoolAuditView {
        return ScheduledFloatPoolAuditView(
            code: item.code,
            labelText: item.label,
            payer: item.payer,
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFloatPoolAuditViews(_ items: [ScheduledFloatPoolAudit]) -> [ScheduledFloatPoolAuditView] {
        var views: [ScheduledFloatPoolAuditView] = []
        for item in items {
            views.append(toScheduledFloatPoolAuditView(item))
        }
        return views
    }

    static func sumScheduledFloatPoolAuditView(_ view: ScheduledFloatPoolAuditView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
