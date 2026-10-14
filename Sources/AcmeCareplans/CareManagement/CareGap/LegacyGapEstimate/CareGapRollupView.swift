import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap rollup.
    final class CareGapRollupView {
        var code: String
        var labelText: String
        var procedureCode: String
        var maximum: String
        var startsAt: String
        var limitText: String
        var marginText: String
        var statusLabel: String

        init(code: String, labelText: String, procedureCode: String, maximum: String, startsAt: String, limitText: String, marginText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.startsAt = startsAt
            self.limitText = limitText
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapRollupView(_ item: CareGapRollup) -> CareGapRollupView {
        return CareGapRollupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            procedureCode: item.procedureCode,
            maximum: String(format: "%.2f", item.maximum),
            startsAt: String(item.startsAt),
            limitText: String(item.limit),
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapRollupViews(_ items: [CareGapRollup]) -> [CareGapRollupView] {
        var views: [CareGapRollupView] = []
        for item in items {
            views.append(toCareGapRollupView(item))
        }
        return views
    }

    static func sumCareGapRollupView(_ view: CareGapRollupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMaximum + Double(parsedStartsAt) + Double(parsedLimit)
    }
}
