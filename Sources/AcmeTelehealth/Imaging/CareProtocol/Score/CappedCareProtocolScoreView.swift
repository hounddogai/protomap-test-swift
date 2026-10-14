import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped care protocol score.
    final class CappedCareProtocolScoreView {
        var code: String
        var title: String
        var floorValue: String
        var attempts: String
        var diagnosisCode: String
        var summary: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, attempts: String, diagnosisCode: String, summary: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCareProtocolScoreView(_ item: CappedCareProtocolScore) -> CappedCareProtocolScoreView {
        return CappedCareProtocolScoreView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            attempts: String(item.attempts),
            diagnosisCode: item.diagnosisCode,
            summary: item.summary,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCareProtocolScoreViews(_ items: [CappedCareProtocolScore]) -> [CappedCareProtocolScoreView] {
        var views: [CappedCareProtocolScoreView] = []
        for item in items {
            views.append(toCappedCareProtocolScoreView(item))
        }
        return views
    }

    static func sumCappedCareProtocolScoreView(_ view: CappedCareProtocolScoreView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedFloorValue + Double(parsedAttempts) + Double(parsedStartsAt)
    }
}
