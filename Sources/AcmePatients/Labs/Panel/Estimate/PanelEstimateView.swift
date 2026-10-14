import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel estimate.
    final class PanelEstimateView {
        var code: String
        var title: String
        var refills: String
        var maximum: String
        var expiresAt: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, refills: String, maximum: String, expiresAt: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refills = refills
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toPanelEstimateView(_ item: PanelEstimate) -> PanelEstimateView {
        return PanelEstimateView(
            code: item.code,
            title: item.title,
            refills: String(item.refills),
            maximum: String(format: "%.2f", item.maximum),
            expiresAt: String(item.expiresAt),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelEstimateViews(_ items: [PanelEstimate]) -> [PanelEstimateView] {
        var views: [PanelEstimateView] = []
        for item in items {
            views.append(toPanelEstimateView(item))
        }
        return views
    }

    static func sumPanelEstimateView(_ view: PanelEstimateView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRefills) + parsedMaximum + Double(parsedExpiresAt)
    }
}
