import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a weighted language request.
    final class WeightedLanguageRequestView {
        var code: String
        var title: String
        var revision: String
        var discount: String
        var specialty: String
        var payer: String
        var bed: String
        var statusLabel: String

        init(code: String, title: String, revision: String, discount: String, specialty: String, payer: String, bed: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.discount = discount
            self.specialty = specialty
            self.payer = payer
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedLanguageRequestView(_ item: WeightedLanguageRequest) -> WeightedLanguageRequestView {
        return WeightedLanguageRequestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            revision: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            specialty: item.specialty,
            payer: Kit.Text.truncate(item.payer, limit: 40),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedLanguageRequestViews(_ items: [WeightedLanguageRequest]) -> [WeightedLanguageRequestView] {
        var views: [WeightedLanguageRequestView] = []
        for item in items {
            views.append(toWeightedLanguageRequestView(item))
        }
        return views
    }

    static func sumWeightedLanguageRequestView(_ view: WeightedLanguageRequestView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRevision) + parsedDiscount
    }
}
