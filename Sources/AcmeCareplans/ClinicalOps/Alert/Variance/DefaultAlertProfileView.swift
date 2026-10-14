import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default alert profile.
    final class DefaultAlertProfileView {
        var codeText: String
        var title: String
        var margin: String
        var maximumText: String
        var specialtyText: String
        var statusLabel: String

        init(codeText: String, title: String, margin: String, maximumText: String, specialtyText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.margin = margin
            self.maximumText = maximumText
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultAlertProfileView(_ item: DefaultAlertProfile) -> DefaultAlertProfileView {
        return DefaultAlertProfileView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            margin: String(format: "%.2f", item.margin),
            maximumText: String(format: "%.2f", item.maximum),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultAlertProfileViews(_ items: [DefaultAlertProfile]) -> [DefaultAlertProfileView] {
        var views: [DefaultAlertProfileView] = []
        for item in items {
            views.append(toDefaultAlertProfileView(item))
        }
        return views
    }

    static func sumDefaultAlertProfileView(_ view: DefaultAlertProfileView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMargin + parsedMaximum
    }
}
