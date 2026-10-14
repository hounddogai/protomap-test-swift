import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study exception.
    final class StudyExceptionView {
        var code: String
        var name: String
        var pinnedText: String
        var ratio: String
        var countryText: String
        var windowDaysText: String
        var graceDays: String
        var title: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, ratio: String, countryText: String, windowDaysText: String, graceDays: String, title: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.ratio = ratio
            self.countryText = countryText
            self.windowDaysText = windowDaysText
            self.graceDays = graceDays
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toStudyExceptionView(_ item: StudyException) -> StudyExceptionView {
        return StudyExceptionView(
            code: item.code,
            name: item.name,
            pinnedText: "\(item.pinned)",
            ratio: String(format: "%.2f", item.ratio),
            countryText: item.country,
            windowDaysText: String(item.windowDays),
            graceDays: String(item.graceDays),
            title: Kit.Text.truncate(item.title, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyExceptionViews(_ items: [StudyException]) -> [StudyExceptionView] {
        var views: [StudyExceptionView] = []
        for item in items {
            views.append(toStudyExceptionView(item))
        }
        return views
    }

    static func sumStudyExceptionView(_ view: StudyExceptionView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedRatio + Double(parsedWindowDays) + Double(parsedGraceDays)
    }
}
