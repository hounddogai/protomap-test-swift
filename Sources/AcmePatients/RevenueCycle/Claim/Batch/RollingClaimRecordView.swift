import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling claim record.
    final class RollingClaimRecordView {
        var code: String
        var nameText: String
        var segment: String
        var description: String
        var expiresAt: String
        var approvedText: String
        var durationMinutes: String
        var maximum: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, nameText: String, segment: String, description: String, expiresAt: String, approvedText: String, durationMinutes: String, maximum: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.segment = segment
            self.description = description
            self.expiresAt = expiresAt
            self.approvedText = approvedText
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRollingClaimRecordView(_ item: RollingClaimRecord) -> RollingClaimRecordView {
        return RollingClaimRecordView(
            code: item.code,
            nameText: item.name,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            description: item.description,
            expiresAt: String(item.expiresAt),
            approvedText: "\(item.approved)",
            durationMinutes: String(item.durationMinutes),
            maximum: String(format: "%.2f", item.maximum),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingClaimRecordViews(_ items: [RollingClaimRecord]) -> [RollingClaimRecordView] {
        var views: [RollingClaimRecordView] = []
        for item in items {
            views.append(toRollingClaimRecordView(item))
        }
        return views
    }

    static func sumRollingClaimRecordView(_ view: RollingClaimRecordView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedDurationMinutes) + parsedMaximum
    }
}
