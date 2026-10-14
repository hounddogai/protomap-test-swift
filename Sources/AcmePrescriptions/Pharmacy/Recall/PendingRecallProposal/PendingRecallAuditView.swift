import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending recall audit.
    final class PendingRecallAuditView {
        var codeText: String
        var title: String
        var retries: String
        var ward: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, title: String, retries: String, ward: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.retries = retries
            self.ward = ward
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRecallAuditView(_ item: PendingRecallAudit) -> PendingRecallAuditView {
        return PendingRecallAuditView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            retries: String(item.retries),
            ward: Kit.Text.truncate(item.ward, limit: 40),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRecallAuditViews(_ items: [PendingRecallAudit]) -> [PendingRecallAuditView] {
        var views: [PendingRecallAuditView] = []
        for item in items {
            views.append(toPendingRecallAuditView(item))
        }
        return views
    }

    static func sumPendingRecallAuditView(_ view: PendingRecallAuditView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedRetries) + Double(parsedVisitMinutes)
    }
}
