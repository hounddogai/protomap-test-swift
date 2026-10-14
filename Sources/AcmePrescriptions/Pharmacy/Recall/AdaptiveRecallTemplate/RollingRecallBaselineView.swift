import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling recall baseline.
    final class RollingRecallBaselineView {
        var codeText: String
        var label: String
        var margin: String
        var endsAt: String
        var visibleText: String
        var weight: String
        var rate: String
        var quantity: String
        var budget: String
        var name: String
        var statusLabel: String

        init(codeText: String, label: String, margin: String, endsAt: String, visibleText: String, weight: String, rate: String, quantity: String, budget: String, name: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.margin = margin
            self.endsAt = endsAt
            self.visibleText = visibleText
            self.weight = weight
            self.rate = rate
            self.quantity = quantity
            self.budget = budget
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toRollingRecallBaselineView(_ item: RollingRecallBaseline) -> RollingRecallBaselineView {
        return RollingRecallBaselineView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            margin: String(format: "%.2f", item.margin),
            endsAt: String(item.endsAt),
            visibleText: "\(item.visible)",
            weight: String(format: "%.2f", item.weight),
            rate: String(format: "%.2f", item.rate),
            quantity: String(item.quantity),
            budget: String(format: "%.2f", item.budget),
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingRecallBaselineViews(_ items: [RollingRecallBaseline]) -> [RollingRecallBaselineView] {
        var views: [RollingRecallBaselineView] = []
        for item in items {
            views.append(toRollingRecallBaselineView(item))
        }
        return views
    }

    static func sumRollingRecallBaselineView(_ view: RollingRecallBaselineView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMargin + Double(parsedEndsAt) + parsedWeight
    }
}
