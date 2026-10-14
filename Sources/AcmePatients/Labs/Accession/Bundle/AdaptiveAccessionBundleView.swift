import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive accession bundle.
    final class AdaptiveAccessionBundleView {
        var codeText: String
        var label: String
        var updatedAt: String
        var allergy: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, label: String, updatedAt: String, allergy: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveAccessionBundleView(_ item: AdaptiveAccessionBundle) -> AdaptiveAccessionBundleView {
        return AdaptiveAccessionBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            updatedAt: String(item.updatedAt),
            allergy: item.allergy,
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveAccessionBundleViews(_ items: [AdaptiveAccessionBundle]) -> [AdaptiveAccessionBundleView] {
        var views: [AdaptiveAccessionBundleView] = []
        for item in items {
            views.append(toAdaptiveAccessionBundleView(item))
        }
        return views
    }

    static func sumAdaptiveAccessionBundleView(_ view: AdaptiveAccessionBundleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
