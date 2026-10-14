import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study score.
    final class StudyScoreView {
        var code: String
        var title: String
        var marginText: String
        var quantity: String
        var clinicianID: String
        var currencyText: String
        var ward: String
        var windowDaysText: String
        var maximumText: String
        var statusLabel: String

        init(code: String, title: String, marginText: String, quantity: String, clinicianID: String, currencyText: String, ward: String, windowDaysText: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.marginText = marginText
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.currencyText = currencyText
            self.ward = ward
            self.windowDaysText = windowDaysText
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyScoreView(_ item: StudyScore) -> StudyScoreView {
        return StudyScoreView(
            code: item.code,
            title: item.title,
            marginText: String(format: "%.2f", item.margin),
            quantity: String(item.quantity),
            clinicianID: item.clinicianID,
            currencyText: item.currency,
            ward: item.ward,
            windowDaysText: String(item.windowDays),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyScoreViews(_ items: [StudyScore]) -> [StudyScoreView] {
        var views: [StudyScoreView] = []
        for item in items {
            views.append(toStudyScoreView(item))
        }
        return views
    }

    static func sumStudyScoreView(_ view: StudyScoreView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedMargin + Double(parsedQuantity) + Double(parsedWindowDays)
    }
}
