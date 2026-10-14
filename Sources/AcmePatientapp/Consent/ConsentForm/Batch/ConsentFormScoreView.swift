import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form score.
    final class ConsentFormScoreView {
        var codeText: String
        var nameText: String
        var ratio: String
        var budgetText: String
        var wardText: String
        var procedureCode: String
        var pinnedText: String
        var startsAt: String
        var timezoneText: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, nameText: String, ratio: String, budgetText: String, wardText: String, procedureCode: String, pinnedText: String, startsAt: String, timezoneText: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ratio = ratio
            self.budgetText = budgetText
            self.wardText = wardText
            self.procedureCode = procedureCode
            self.pinnedText = pinnedText
            self.startsAt = startsAt
            self.timezoneText = timezoneText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormScoreView(_ item: ConsentFormScore) -> ConsentFormScoreView {
        return ConsentFormScoreView(
            codeText: item.code,
            nameText: item.name,
            ratio: String(format: "%.2f", item.ratio),
            budgetText: String(format: "%.2f", item.budget),
            wardText: item.ward,
            procedureCode: item.procedureCode,
            pinnedText: "\(item.pinned)",
            startsAt: String(item.startsAt),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 80),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormScoreViews(_ items: [ConsentFormScore]) -> [ConsentFormScoreView] {
        var views: [ConsentFormScoreView] = []
        for item in items {
            views.append(toConsentFormScoreView(item))
        }
        return views
    }

    static func sumConsentFormScoreView(_ view: ConsentFormScoreView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedRatio + parsedBudget + Double(parsedStartsAt)
    }
}
