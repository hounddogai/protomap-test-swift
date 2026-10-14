import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict witness audit.
    final class StrictWitnessAuditView {
        var code: String
        var label: String
        var updatedAtText: String
        var phone: String
        var channel: String
        var version: String
        var statusLabel: String

        init(code: String, label: String, updatedAtText: String, phone: String, channel: String, version: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.updatedAtText = updatedAtText
            self.phone = phone
            self.channel = channel
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toStrictWitnessAuditView(_ item: StrictWitnessAudit) -> StrictWitnessAuditView {
        return StrictWitnessAuditView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            updatedAtText: String(item.updatedAt),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictWitnessAuditViews(_ items: [StrictWitnessAudit]) -> [StrictWitnessAuditView] {
        var views: [StrictWitnessAuditView] = []
        for item in items {
            views.append(toStrictWitnessAuditView(item))
        }
        return views
    }

    static func sumStrictWitnessAuditView(_ view: StrictWitnessAuditView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVersion)
    }
}
