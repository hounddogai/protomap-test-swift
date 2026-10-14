import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy recall template.
    final class LegacyRecallTemplateView {
        var codeText: String
        var title: String
        var minimumText: String
        var unit: String
        var clinicianID: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, title: String, minimumText: String, unit: String, clinicianID: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.minimumText = minimumText
            self.unit = unit
            self.clinicianID = clinicianID
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyRecallTemplateView(_ item: LegacyRecallTemplate) -> LegacyRecallTemplateView {
        return LegacyRecallTemplateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            minimumText: String(format: "%.2f", item.minimum),
            unit: item.unit,
            clinicianID: item.clinicianID,
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyRecallTemplateViews(_ items: [LegacyRecallTemplate]) -> [LegacyRecallTemplateView] {
        var views: [LegacyRecallTemplateView] = []
        for item in items {
            views.append(toLegacyRecallTemplateView(item))
        }
        return views
    }

    static func sumLegacyRecallTemplateView(_ view: LegacyRecallTemplateView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
