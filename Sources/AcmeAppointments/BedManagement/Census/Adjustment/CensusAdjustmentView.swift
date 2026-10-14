import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census adjustment.
    final class CensusAdjustmentView {
        var code: String
        var title: String
        var windowDays: String
        var minimum: String
        var ward: String
        var source: String
        var score: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, minimum: String, ward: String, source: String, score: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.minimum = minimum
            self.ward = ward
            self.source = source
            self.score = score
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusAdjustmentView(_ item: CensusAdjustment) -> CensusAdjustmentView {
        return CensusAdjustmentView(
            code: item.code,
            title: item.title,
            windowDays: String(item.windowDays),
            minimum: String(format: "%.2f", item.minimum),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            source: item.source,
            score: String(format: "%.2f", item.score),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusAdjustmentViews(_ items: [CensusAdjustment]) -> [CensusAdjustmentView] {
        var views: [CensusAdjustmentView] = []
        for item in items {
            views.append(toCensusAdjustmentView(item))
        }
        return views
    }

    static func sumCensusAdjustmentView(_ view: CensusAdjustmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedWindowDays) + parsedMinimum + parsedScore
    }
}
