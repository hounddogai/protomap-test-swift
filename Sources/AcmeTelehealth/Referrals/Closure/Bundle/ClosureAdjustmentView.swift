import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure adjustment.
    final class ClosureAdjustmentView {
        var codeText: String
        var title: String
        var marginText: String
        var country: String
        var copay: String
        var weight: String
        var ratioText: String
        var statusLabel: String

        init(codeText: String, title: String, marginText: String, country: String, copay: String, weight: String, ratioText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.marginText = marginText
            self.country = country
            self.copay = copay
            self.weight = weight
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureAdjustmentView(_ item: ClosureAdjustment) -> ClosureAdjustmentView {
        return ClosureAdjustmentView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            marginText: String(format: "%.2f", item.margin),
            country: item.country,
            copay: String(format: "%.2f", item.copay),
            weight: String(format: "%.2f", item.weight),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureAdjustmentViews(_ items: [ClosureAdjustment]) -> [ClosureAdjustmentView] {
        var views: [ClosureAdjustmentView] = []
        for item in items {
            views.append(toClosureAdjustmentView(item))
        }
        return views
    }

    static func sumClosureAdjustmentView(_ view: ClosureAdjustmentView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMargin + parsedCopay + parsedWeight
    }
}
