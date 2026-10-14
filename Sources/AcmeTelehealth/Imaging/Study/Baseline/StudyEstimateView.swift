import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study estimate.
    final class StudyEstimateView {
        var code: String
        var name: String
        var startsAt: String
        var summaryText: String
        var rate: String
        var floorValue: String
        var timezoneText: String
        var refills: String
        var limitText: String
        var minimumText: String
        var statusLabel: String

        init(code: String, name: String, startsAt: String, summaryText: String, rate: String, floorValue: String, timezoneText: String, refills: String, limitText: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.summaryText = summaryText
            self.rate = rate
            self.floorValue = floorValue
            self.timezoneText = timezoneText
            self.refills = refills
            self.limitText = limitText
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyEstimateView(_ item: StudyEstimate) -> StudyEstimateView {
        return StudyEstimateView(
            code: item.code,
            name: item.name,
            startsAt: String(item.startsAt),
            summaryText: item.summary,
            rate: String(format: "%.2f", item.rate),
            floorValue: String(format: "%.2f", item.floorValue),
            timezoneText: item.timezone,
            refills: String(item.refills),
            limitText: String(item.limit),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyEstimateViews(_ items: [StudyEstimate]) -> [StudyEstimateView] {
        var views: [StudyEstimateView] = []
        for item in items {
            views.append(toStudyEstimateView(item))
        }
        return views
    }

    static func sumStudyEstimateView(_ view: StudyEstimateView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedStartsAt) + parsedRate + parsedFloorValue
    }
}
