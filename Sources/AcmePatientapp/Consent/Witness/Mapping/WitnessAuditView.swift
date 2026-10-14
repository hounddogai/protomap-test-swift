import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness audit.
    final class WitnessAuditView {
        var codeText: String
        var title: String
        var active: String
        var archived: String
        var description: String
        var versionText: String
        var statusLabel: String

        init(codeText: String, title: String, active: String, archived: String, description: String, versionText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.active = active
            self.archived = archived
            self.description = description
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessAuditView(_ item: WitnessAudit) -> WitnessAuditView {
        return WitnessAuditView(
            codeText: item.code,
            title: item.title,
            active: "\(item.active)",
            archived: "\(item.archived)",
            description: item.description,
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessAuditViews(_ items: [WitnessAudit]) -> [WitnessAuditView] {
        var views: [WitnessAuditView] = []
        for item in items {
            views.append(toWitnessAuditView(item))
        }
        return views
    }

    static func sumWitnessAuditView(_ view: WitnessAuditView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
