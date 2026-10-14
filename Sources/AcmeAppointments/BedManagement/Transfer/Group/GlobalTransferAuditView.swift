import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global transfer audit.
    final class GlobalTransferAuditView {
        var code: String
        var name: String
        var windowDays: String
        var checksum: String
        var score: String
        var externalRef: String
        var approved: String
        var ownerID: String
        var discount: String
        var threshold: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, checksum: String, score: String, externalRef: String, approved: String, ownerID: String, discount: String, threshold: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.checksum = checksum
            self.score = score
            self.externalRef = externalRef
            self.approved = approved
            self.ownerID = ownerID
            self.discount = discount
            self.threshold = threshold
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalTransferAuditView(_ item: GlobalTransferAudit) -> GlobalTransferAuditView {
        return GlobalTransferAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            windowDays: String(item.windowDays),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            score: String(format: "%.2f", item.score),
            externalRef: item.externalRef,
            approved: "\(item.approved)",
            ownerID: item.ownerID,
            discount: String(format: "%.2f", item.discount),
            threshold: String(format: "%.2f", item.threshold),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalTransferAuditViews(_ items: [GlobalTransferAudit]) -> [GlobalTransferAuditView] {
        var views: [GlobalTransferAuditView] = []
        for item in items {
            views.append(toGlobalTransferAuditView(item))
        }
        return views
    }

    static func sumGlobalTransferAuditView(_ view: GlobalTransferAuditView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedWindowDays) + parsedScore + parsedDiscount
    }
}
