import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel variance.
    final class PanelVarianceView {
        var code: String
        var label: String
        var graceDaysText: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, graceDaysText: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.graceDaysText = graceDaysText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toPanelVarianceView(_ item: PanelVariance) -> PanelVarianceView {
        return PanelVarianceView(
            code: item.code,
            label: item.label,
            graceDaysText: String(item.graceDays),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelVarianceViews(_ items: [PanelVariance]) -> [PanelVarianceView] {
        var views: [PanelVarianceView] = []
        for item in items {
            views.append(toPanelVarianceView(item))
        }
        return views
    }

    static func sumPanelVarianceView(_ view: PanelVarianceView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
