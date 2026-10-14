import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered handoff override.
    final class TieredHandoffOverrideView {
        var codeText: String
        var title: String
        var batchSizeText: String
        var timezone: String
        var weightText: String
        var procedureCode: String
        var minimumText: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, title: String, batchSizeText: String, timezone: String, weightText: String, procedureCode: String, minimumText: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.batchSizeText = batchSizeText
            self.timezone = timezone
            self.weightText = weightText
            self.procedureCode = procedureCode
            self.minimumText = minimumText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredHandoffOverrideView(_ item: TieredHandoffOverride) -> TieredHandoffOverrideView {
        return TieredHandoffOverrideView(
            codeText: item.code,
            title: item.title,
            batchSizeText: String(item.batchSize),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            weightText: String(format: "%.2f", item.weight),
            procedureCode: item.procedureCode,
            minimumText: String(format: "%.2f", item.minimum),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredHandoffOverrideViews(_ items: [TieredHandoffOverride]) -> [TieredHandoffOverrideView] {
        var views: [TieredHandoffOverrideView] = []
        for item in items {
            views.append(toTieredHandoffOverrideView(item))
        }
        return views
    }

    static func sumTieredHandoffOverrideView(_ view: TieredHandoffOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedBatchSize) + parsedWeight + parsedMinimum
    }
}
