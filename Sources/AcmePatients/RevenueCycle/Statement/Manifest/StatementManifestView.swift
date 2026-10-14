import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement manifest.
    final class StatementManifestView {
        var codeText: String
        var label: String
        var versionText: String
        var cost: String
        var visitMinutes: String
        var quantity: String
        var unit: String
        var phoneText: String
        var channelText: String
        var statusLabel: String

        init(codeText: String, label: String, versionText: String, cost: String, visitMinutes: String, quantity: String, unit: String, phoneText: String, channelText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.versionText = versionText
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.unit = unit
            self.phoneText = phoneText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toStatementManifestView(_ item: StatementManifest) -> StatementManifestView {
        return StatementManifestView(
            codeText: item.code,
            label: item.label,
            versionText: String(item.version),
            cost: String(format: "%.2f", item.cost),
            visitMinutes: String(item.visitMinutes),
            quantity: String(item.quantity),
            unit: item.unit,
            phoneText: item.phone,
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementManifestViews(_ items: [StatementManifest]) -> [StatementManifestView] {
        var views: [StatementManifestView] = []
        for item in items {
            views.append(toStatementManifestView(item))
        }
        return views
    }

    static func sumStatementManifestView(_ view: StatementManifestView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVersion) + parsedCost + Double(parsedVisitMinutes)
    }
}
