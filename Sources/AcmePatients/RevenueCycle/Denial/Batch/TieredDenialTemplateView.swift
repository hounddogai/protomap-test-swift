import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered denial template.
    final class TieredDenialTemplateView {
        var codeText: String
        var title: String
        var acuity: String
        var marginText: String
        var dosageMg: String
        var statusLabel: String

        init(codeText: String, title: String, acuity: String, marginText: String, dosageMg: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.acuity = acuity
            self.marginText = marginText
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toTieredDenialTemplateView(_ item: TieredDenialTemplate) -> TieredDenialTemplateView {
        return TieredDenialTemplateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            acuity: String(item.acuity),
            marginText: String(format: "%.2f", item.margin),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredDenialTemplateViews(_ items: [TieredDenialTemplate]) -> [TieredDenialTemplateView] {
        var views: [TieredDenialTemplateView] = []
        for item in items {
            views.append(toTieredDenialTemplateView(item))
        }
        return views
    }

    static func sumTieredDenialTemplateView(_ view: TieredDenialTemplateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAcuity) + parsedMargin + parsedDosageMg
    }
}
