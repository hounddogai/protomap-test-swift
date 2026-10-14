import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback cleaning template.
    final class FallbackCleaningTemplateView {
        var codeText: String
        var nameText: String
        var unitText: String
        var externalRef: String
        var country: String
        var createdAtText: String
        var timezoneText: String
        var payer: String
        var minimum: String
        var title: String
        var statusLabel: String

        init(codeText: String, nameText: String, unitText: String, externalRef: String, country: String, createdAtText: String, timezoneText: String, payer: String, minimum: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.unitText = unitText
            self.externalRef = externalRef
            self.country = country
            self.createdAtText = createdAtText
            self.timezoneText = timezoneText
            self.payer = payer
            self.minimum = minimum
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCleaningTemplateView(_ item: FallbackCleaningTemplate) -> FallbackCleaningTemplateView {
        return FallbackCleaningTemplateView(
            codeText: item.code,
            nameText: item.name,
            unitText: item.unit,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            country: item.country,
            createdAtText: String(item.createdAt),
            timezoneText: item.timezone,
            payer: item.payer,
            minimum: String(format: "%.2f", item.minimum),
            title: Kit.Text.truncate(item.title, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCleaningTemplateViews(_ items: [FallbackCleaningTemplate]) -> [FallbackCleaningTemplateView] {
        var views: [FallbackCleaningTemplateView] = []
        for item in items {
            views.append(toFallbackCleaningTemplateView(item))
        }
        return views
    }

    static func sumFallbackCleaningTemplateView(_ view: FallbackCleaningTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedCreatedAt) + parsedMinimum
    }
}
