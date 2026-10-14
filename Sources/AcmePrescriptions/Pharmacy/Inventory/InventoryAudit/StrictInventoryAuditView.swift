import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict inventory audit.
    final class StrictInventoryAuditView {
        var codeText: String
        var name: String
        var score: String
        var segment: String
        var externalRef: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, name: String, score: String, segment: String, externalRef: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.score = score
            self.segment = segment
            self.externalRef = externalRef
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toStrictInventoryAuditView(_ item: StrictInventoryAudit) -> StrictInventoryAuditView {
        return StrictInventoryAuditView(
            codeText: item.code,
            name: item.name,
            score: String(format: "%.2f", item.score),
            segment: item.segment,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictInventoryAuditViews(_ items: [StrictInventoryAudit]) -> [StrictInventoryAuditView] {
        var views: [StrictInventoryAuditView] = []
        for item in items {
            views.append(toStrictInventoryAuditView(item))
        }
        return views
    }

    static func sumStrictInventoryAuditView(_ view: StrictInventoryAuditView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
