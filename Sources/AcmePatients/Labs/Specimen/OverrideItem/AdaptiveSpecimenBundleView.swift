import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive specimen bundle.
    final class AdaptiveSpecimenBundleView {
        var codeText: String
        var labelText: String
        var bedText: String
        var currency: String
        var graceDaysText: String
        var procedureCode: String
        var unit: String
        var title: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, labelText: String, bedText: String, currency: String, graceDaysText: String, procedureCode: String, unit: String, title: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.bedText = bedText
            self.currency = currency
            self.graceDaysText = graceDaysText
            self.procedureCode = procedureCode
            self.unit = unit
            self.title = title
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveSpecimenBundleView(_ item: AdaptiveSpecimenBundle) -> AdaptiveSpecimenBundleView {
        return AdaptiveSpecimenBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            currency: item.currency,
            graceDaysText: String(item.graceDays),
            procedureCode: item.procedureCode,
            unit: item.unit,
            title: item.title,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveSpecimenBundleViews(_ items: [AdaptiveSpecimenBundle]) -> [AdaptiveSpecimenBundleView] {
        var views: [AdaptiveSpecimenBundleView] = []
        for item in items {
            views.append(toAdaptiveSpecimenBundleView(item))
        }
        return views
    }

    static func sumAdaptiveSpecimenBundleView(_ view: AdaptiveSpecimenBundleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedExpiresAt)
    }
}
