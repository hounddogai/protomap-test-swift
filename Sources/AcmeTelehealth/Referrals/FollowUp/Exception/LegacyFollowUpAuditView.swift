import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy follow up audit.
    final class LegacyFollowUpAuditView {
        var code: String
        var label: String
        var weight: String
        var maximumText: String
        var revision: String
        var refills: String
        var timezone: String
        var batchSize: String
        var statusLabel: String

        init(code: String, label: String, weight: String, maximumText: String, revision: String, refills: String, timezone: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.maximumText = maximumText
            self.revision = revision
            self.refills = refills
            self.timezone = timezone
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFollowUpAuditView(_ item: LegacyFollowUpAudit) -> LegacyFollowUpAuditView {
        return LegacyFollowUpAuditView(
            code: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            maximumText: String(format: "%.2f", item.maximum),
            revision: String(item.revision),
            refills: String(item.refills),
            timezone: item.timezone,
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFollowUpAuditViews(_ items: [LegacyFollowUpAudit]) -> [LegacyFollowUpAuditView] {
        var views: [LegacyFollowUpAuditView] = []
        for item in items {
            views.append(toLegacyFollowUpAuditView(item))
        }
        return views
    }

    static func sumLegacyFollowUpAuditView(_ view: LegacyFollowUpAuditView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedWeight + parsedMaximum + Double(parsedRevision)
    }
}
