import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language entry.
    final class LanguageEntryView {
        var code: String
        var label: String
        var copayText: String
        var acuityText: String
        var limit: String
        var retries: String
        var ceiling: String
        var statusLabel: String

        init(code: String, label: String, copayText: String, acuityText: String, limit: String, retries: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copayText = copayText
            self.acuityText = acuityText
            self.limit = limit
            self.retries = retries
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageEntryView(_ item: LanguageEntry) -> LanguageEntryView {
        return LanguageEntryView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            copayText: String(format: "%.2f", item.copay),
            acuityText: String(item.acuity),
            limit: String(item.limit),
            retries: String(item.retries),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageEntryViews(_ items: [LanguageEntry]) -> [LanguageEntryView] {
        var views: [LanguageEntryView] = []
        for item in items {
            views.append(toLanguageEntryView(item))
        }
        return views
    }

    static func sumLanguageEntryView(_ view: LanguageEntryView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCopay + Double(parsedAcuity) + Double(parsedLimit)
    }
}
