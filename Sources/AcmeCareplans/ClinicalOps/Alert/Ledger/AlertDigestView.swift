import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert digest.
    final class AlertDigestView {
        var code: String
        var label: String
        var allergyText: String
        var updatedAt: String
        var version: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, allergyText: String, updatedAt: String, version: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergyText = allergyText
            self.updatedAt = updatedAt
            self.version = version
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAlertDigestView(_ item: AlertDigest) -> AlertDigestView {
        return AlertDigestView(
            code: item.code,
            label: item.label,
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            updatedAt: String(item.updatedAt),
            version: String(item.version),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertDigestViews(_ items: [AlertDigest]) -> [AlertDigestView] {
        var views: [AlertDigestView] = []
        for item in items {
            views.append(toAlertDigestView(item))
        }
        return views
    }

    static func sumAlertDigestView(_ view: AlertDigestView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVersion) + Double(parsedVisitMinutes)
    }
}
