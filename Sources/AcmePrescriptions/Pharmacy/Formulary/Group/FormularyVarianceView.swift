import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary variance.
    final class FormularyVarianceView {
        var code: String
        var title: String
        var category: String
        var margin: String
        var label: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, category: String, margin: String, label: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.category = category
            self.margin = margin
            self.label = label
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyVarianceView(_ item: FormularyVariance) -> FormularyVarianceView {
        return FormularyVarianceView(
            code: item.code,
            title: item.title,
            category: Kit.Text.truncate(item.category, limit: 64),
            margin: String(format: "%.2f", item.margin),
            label: item.label,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyVarianceViews(_ items: [FormularyVariance]) -> [FormularyVarianceView] {
        var views: [FormularyVarianceView] = []
        for item in items {
            views.append(toFormularyVarianceView(item))
        }
        return views
    }

    static func sumFormularyVarianceView(_ view: FormularyVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
