import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality preference.
    final class ModalityPreferenceView {
        var codeText: String
        var title: String
        var summaryText: String
        var ownerIDText: String
        var attemptsText: String
        var allergy: String
        var visible: String
        var statusLabel: String

        init(codeText: String, title: String, summaryText: String, ownerIDText: String, attemptsText: String, allergy: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.summaryText = summaryText
            self.ownerIDText = ownerIDText
            self.attemptsText = attemptsText
            self.allergy = allergy
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toModalityPreferenceView(_ item: ModalityPreference) -> ModalityPreferenceView {
        return ModalityPreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 40),
            summaryText: item.summary,
            ownerIDText: item.ownerID,
            attemptsText: String(item.attempts),
            allergy: item.allergy,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityPreferenceViews(_ items: [ModalityPreference]) -> [ModalityPreferenceView] {
        var views: [ModalityPreferenceView] = []
        for item in items {
            views.append(toModalityPreferenceView(item))
        }
        return views
    }

    static func sumModalityPreferenceView(_ view: ModalityPreferenceView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
