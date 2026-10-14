import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional remittance rule.
    final class RegionalRemittanceRuleView {
        var codeText: String
        var labelText: String
        var margin: String
        var updatedAt: String
        var visitMinutes: String
        var minimumText: String
        var visible: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, labelText: String, margin: String, updatedAt: String, visitMinutes: String, minimumText: String, visible: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.margin = margin
            self.updatedAt = updatedAt
            self.visitMinutes = visitMinutes
            self.minimumText = minimumText
            self.visible = visible
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRemittanceRuleView(_ item: RegionalRemittanceRule) -> RegionalRemittanceRuleView {
        return RegionalRemittanceRuleView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            margin: String(format: "%.2f", item.margin),
            updatedAt: String(item.updatedAt),
            visitMinutes: String(item.visitMinutes),
            minimumText: String(format: "%.2f", item.minimum),
            visible: "\(item.visible)",
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRemittanceRuleViews(_ items: [RegionalRemittanceRule]) -> [RegionalRemittanceRuleView] {
        var views: [RegionalRemittanceRuleView] = []
        for item in items {
            views.append(toRegionalRemittanceRuleView(item))
        }
        return views
    }

    static func sumRegionalRemittanceRuleView(_ view: RegionalRemittanceRuleView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMargin + Double(parsedUpdatedAt) + Double(parsedVisitMinutes)
    }
}
