import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language estimate.
    final class LanguageEstimateView {
        var code: String
        var title: String
        var facilityText: String
        var discountText: String
        var revisionText: String
        var source: String
        var allergyText: String
        var visible: String
        var retries: String
        var statusLabel: String

        init(code: String, title: String, facilityText: String, discountText: String, revisionText: String, source: String, allergyText: String, visible: String, retries: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.facilityText = facilityText
            self.discountText = discountText
            self.revisionText = revisionText
            self.source = source
            self.allergyText = allergyText
            self.visible = visible
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageEstimateView(_ item: LanguageEstimate) -> LanguageEstimateView {
        return LanguageEstimateView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            facilityText: item.facility,
            discountText: String(format: "%.2f", item.discount),
            revisionText: String(item.revision),
            source: item.source,
            allergyText: item.allergy,
            visible: "\(item.visible)",
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageEstimateViews(_ items: [LanguageEstimate]) -> [LanguageEstimateView] {
        var views: [LanguageEstimateView] = []
        for item in items {
            views.append(toLanguageEstimateView(item))
        }
        return views
    }

    static func sumLanguageEstimateView(_ view: LanguageEstimateView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedDiscount + Double(parsedRevision) + Double(parsedRetries)
    }
}
