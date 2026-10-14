import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach audit.
    final class OutreachAuditView {
        var code: String
        var name: String
        var channelText: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, name: String, channelText: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.channelText = channelText
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachAuditView(_ item: OutreachAudit) -> OutreachAuditView {
        return OutreachAuditView(
            code: item.code,
            name: item.name,
            channelText: item.channel,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachAuditViews(_ items: [OutreachAudit]) -> [OutreachAuditView] {
        var views: [OutreachAuditView] = []
        for item in items {
            views.append(toOutreachAuditView(item))
        }
        return views
    }

    static func sumOutreachAuditView(_ view: OutreachAuditView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
