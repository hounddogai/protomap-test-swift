import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted rounding profile.
    final class WeightedRoundingProfileView {
        var code: String
        var label: String
        var procedureCode: String
        var batchSizeText: String
        var ownerID: String
        var graceDays: String
        var category: String
        var timezoneText: String
        var limitText: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, batchSizeText: String, ownerID: String, graceDays: String, category: String, timezoneText: String, limitText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.batchSizeText = batchSizeText
            self.ownerID = ownerID
            self.graceDays = graceDays
            self.category = category
            self.timezoneText = timezoneText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRoundingProfileView(_ item: WeightedRoundingProfile) -> WeightedRoundingProfileView {
        return WeightedRoundingProfileView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            procedureCode: item.procedureCode,
            batchSizeText: String(item.batchSize),
            ownerID: item.ownerID,
            graceDays: String(item.graceDays),
            category: item.category,
            timezoneText: item.timezone,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRoundingProfileViews(_ items: [WeightedRoundingProfile]) -> [WeightedRoundingProfileView] {
        var views: [WeightedRoundingProfileView] = []
        for item in items {
            views.append(toWeightedRoundingProfileView(item))
        }
        return views
    }

    static func sumWeightedRoundingProfileView(_ view: WeightedRoundingProfileView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays) + Double(parsedLimit)
    }
}
