import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial group.
    final class DenialGroupView {
        var code: String
        var title: String
        var externalRefText: String
        var timezone: String
        var active: String
        var refills: String
        var durationMinutes: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, timezone: String, active: String, refills: String, durationMinutes: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.timezone = timezone
            self.active = active
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toDenialGroupView(_ item: DenialGroup) -> DenialGroupView {
        return DenialGroupView(
            code: item.code,
            title: item.title,
            externalRefText: item.externalRef,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            active: "\(item.active)",
            refills: String(item.refills),
            durationMinutes: String(item.durationMinutes),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialGroupViews(_ items: [DenialGroup]) -> [DenialGroupView] {
        var views: [DenialGroupView] = []
        for item in items {
            views.append(toDenialGroupView(item))
        }
        return views
    }

    static func sumDenialGroupView(_ view: DenialGroupView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedRefills) + Double(parsedDurationMinutes) + parsedCost
    }
}
