import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback panel group.
    final class FallbackPanelGroupView {
        var code: String
        var name: String
        var reviewer: String
        var ceilingText: String
        var durationMinutes: String
        var expiresAt: String
        var acuity: String
        var dosageMg: String
        var startsAt: String
        var statusLabel: String

        init(code: String, name: String, reviewer: String, ceilingText: String, durationMinutes: String, expiresAt: String, acuity: String, dosageMg: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.ceilingText = ceilingText
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.acuity = acuity
            self.dosageMg = dosageMg
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackPanelGroupView(_ item: FallbackPanelGroup) -> FallbackPanelGroupView {
        return FallbackPanelGroupView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            reviewer: item.reviewer,
            ceilingText: String(format: "%.2f", item.ceiling),
            durationMinutes: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            acuity: String(item.acuity),
            dosageMg: String(format: "%.2f", item.dosageMg),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackPanelGroupViews(_ items: [FallbackPanelGroup]) -> [FallbackPanelGroupView] {
        var views: [FallbackPanelGroupView] = []
        for item in items {
            views.append(toFallbackPanelGroupView(item))
        }
        return views
    }

    static func sumFallbackPanelGroupView(_ view: FallbackPanelGroupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCeiling + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
