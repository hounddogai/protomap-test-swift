import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language profile.
    final class LanguageProfileView {
        var code: String
        var name: String
        var minimumText: String
        var bed: String
        var title: String
        var statusLabel: String

        init(code: String, name: String, minimumText: String, bed: String, title: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimumText = minimumText
            self.bed = bed
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageProfileView(_ item: LanguageProfile) -> LanguageProfileView {
        return LanguageProfileView(
            code: item.code,
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            bed: item.bed,
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageProfileViews(_ items: [LanguageProfile]) -> [LanguageProfileView] {
        var views: [LanguageProfileView] = []
        for item in items {
            views.append(toLanguageProfileView(item))
        }
        return views
    }

    static func sumLanguageProfileView(_ view: LanguageProfileView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
