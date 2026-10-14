import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default read baseline.
    final class DefaultReadBaselineView {
        var codeText: String
        var name: String
        var title: String
        var maximum: String
        var cost: String
        var revision: String
        var approved: String
        var copay: String
        var pinned: String
        var statusLabel: String

        init(codeText: String, name: String, title: String, maximum: String, cost: String, revision: String, approved: String, copay: String, pinned: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.title = title
            self.maximum = maximum
            self.cost = cost
            self.revision = revision
            self.approved = approved
            self.copay = copay
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultReadBaselineView(_ item: DefaultReadBaseline) -> DefaultReadBaselineView {
        return DefaultReadBaselineView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            cost: String(format: "%.2f", item.cost),
            revision: String(item.revision),
            approved: "\(item.approved)",
            copay: String(format: "%.2f", item.copay),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultReadBaselineViews(_ items: [DefaultReadBaseline]) -> [DefaultReadBaselineView] {
        var views: [DefaultReadBaselineView] = []
        for item in items {
            views.append(toDefaultReadBaselineView(item))
        }
        return views
    }

    static func sumDefaultReadBaselineView(_ view: DefaultReadBaselineView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedMaximum + parsedCost + Double(parsedRevision)
    }
}
