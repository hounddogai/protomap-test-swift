import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language notice.
    final class LanguageNoticeView {
        var code: String
        var title: String
        var budgetText: String
        var capacity: String
        var startsAtText: String
        var endsAtText: String
        var diagnosisCode: String
        var batchSize: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, title: String, budgetText: String, capacity: String, startsAtText: String, endsAtText: String, diagnosisCode: String, batchSize: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budgetText = budgetText
            self.capacity = capacity
            self.startsAtText = startsAtText
            self.endsAtText = endsAtText
            self.diagnosisCode = diagnosisCode
            self.batchSize = batchSize
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageNoticeView(_ item: LanguageNotice) -> LanguageNoticeView {
        return LanguageNoticeView(
            code: item.code,
            title: item.title,
            budgetText: String(format: "%.2f", item.budget),
            capacity: String(item.capacity),
            startsAtText: String(item.startsAt),
            endsAtText: String(item.endsAt),
            diagnosisCode: item.diagnosisCode,
            batchSize: String(item.batchSize),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageNoticeViews(_ items: [LanguageNotice]) -> [LanguageNoticeView] {
        var views: [LanguageNoticeView] = []
        for item in items {
            views.append(toLanguageNoticeView(item))
        }
        return views
    }

    static func sumLanguageNoticeView(_ view: LanguageNoticeView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedBudget + Double(parsedCapacity) + Double(parsedStartsAt)
    }
}
