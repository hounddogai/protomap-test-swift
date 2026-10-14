import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure window.
    final class ClosureWindowView {
        var codeText: String
        var label: String
        var rateText: String
        var diagnosisCodeText: String
        var endsAt: String
        var summary: String
        var refills: String
        var minimumText: String
        var allergy: String
        var localeText: String
        var titleText: String
        var statusLabel: String

        init(codeText: String, label: String, rateText: String, diagnosisCodeText: String, endsAt: String, summary: String, refills: String, minimumText: String, allergy: String, localeText: String, titleText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.rateText = rateText
            self.diagnosisCodeText = diagnosisCodeText
            self.endsAt = endsAt
            self.summary = summary
            self.refills = refills
            self.minimumText = minimumText
            self.allergy = allergy
            self.localeText = localeText
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureWindowView(_ item: ClosureWindow) -> ClosureWindowView {
        return ClosureWindowView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            rateText: String(format: "%.2f", item.rate),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            endsAt: String(item.endsAt),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            refills: String(item.refills),
            minimumText: String(format: "%.2f", item.minimum),
            allergy: item.allergy,
            localeText: Kit.Text.truncate(item.locale, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureWindowViews(_ items: [ClosureWindow]) -> [ClosureWindowView] {
        var views: [ClosureWindowView] = []
        for item in items {
            views.append(toClosureWindowView(item))
        }
        return views
    }

    static func sumClosureWindowView(_ view: ClosureWindowView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRate + Double(parsedEndsAt) + Double(parsedRefills)
    }
}
