import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel exception.
    final class PanelExceptionView {
        var codeText: String
        var nameText: String
        var locale: String
        var notes: String
        var startsAtText: String
        var diagnosisCodeText: String
        var maximum: String
        var statusLabel: String

        init(codeText: String, nameText: String, locale: String, notes: String, startsAtText: String, diagnosisCodeText: String, maximum: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.locale = locale
            self.notes = notes
            self.startsAtText = startsAtText
            self.diagnosisCodeText = diagnosisCodeText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toPanelExceptionView(_ item: PanelException) -> PanelExceptionView {
        return PanelExceptionView(
            codeText: item.code,
            nameText: item.name,
            locale: item.locale,
            notes: Kit.Text.truncate(item.notes, limit: 64),
            startsAtText: String(item.startsAt),
            diagnosisCodeText: item.diagnosisCode,
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelExceptionViews(_ items: [PanelException]) -> [PanelExceptionView] {
        var views: [PanelExceptionView] = []
        for item in items {
            views.append(toPanelExceptionView(item))
        }
        return views
    }

    static func sumPanelExceptionView(_ view: PanelExceptionView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedStartsAt) + parsedMaximum
    }
}
