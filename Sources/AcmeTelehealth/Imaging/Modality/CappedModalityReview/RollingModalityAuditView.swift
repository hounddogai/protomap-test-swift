import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling modality audit.
    final class RollingModalityAuditView {
        var code: String
        var title: String
        var score: String
        var locale: String
        var unit: String
        var payer: String
        var segment: String
        var ceiling: String
        var priority: String
        var pinned: String
        var statusLabel: String

        init(code: String, title: String, score: String, locale: String, unit: String, payer: String, segment: String, ceiling: String, priority: String, pinned: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.score = score
            self.locale = locale
            self.unit = unit
            self.payer = payer
            self.segment = segment
            self.ceiling = ceiling
            self.priority = priority
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toRollingModalityAuditView(_ item: RollingModalityAudit) -> RollingModalityAuditView {
        return RollingModalityAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            score: String(format: "%.2f", item.score),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            payer: item.payer,
            segment: Kit.Text.truncate(item.segment, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            priority: String(item.priority),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingModalityAuditViews(_ items: [RollingModalityAudit]) -> [RollingModalityAuditView] {
        var views: [RollingModalityAuditView] = []
        for item in items {
            views.append(toRollingModalityAuditView(item))
        }
        return views
    }

    static func sumRollingModalityAuditView(_ view: RollingModalityAuditView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedScore + parsedCeiling + Double(parsedPriority)
    }
}
