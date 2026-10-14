import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional float pool override.
    final class RegionalFloatPoolOverrideView {
        var code: String
        var title: String
        var description: String
        var category: String
        var batchSize: String
        var checksumText: String
        var diagnosisCode: String
        var budget: String
        var ownerIDText: String
        var summary: String
        var statusLabel: String

        init(code: String, title: String, description: String, category: String, batchSize: String, checksumText: String, diagnosisCode: String, budget: String, ownerIDText: String, summary: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.category = category
            self.batchSize = batchSize
            self.checksumText = checksumText
            self.diagnosisCode = diagnosisCode
            self.budget = budget
            self.ownerIDText = ownerIDText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFloatPoolOverrideView(_ item: RegionalFloatPoolOverride) -> RegionalFloatPoolOverrideView {
        return RegionalFloatPoolOverrideView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            description: item.description,
            category: Kit.Text.truncate(item.category, limit: 120),
            batchSize: String(item.batchSize),
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            budget: String(format: "%.2f", item.budget),
            ownerIDText: item.ownerID,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFloatPoolOverrideViews(_ items: [RegionalFloatPoolOverride]) -> [RegionalFloatPoolOverrideView] {
        var views: [RegionalFloatPoolOverrideView] = []
        for item in items {
            views.append(toRegionalFloatPoolOverrideView(item))
        }
        return views
    }

    static func sumRegionalFloatPoolOverrideView(_ view: RegionalFloatPoolOverrideView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedBatchSize) + parsedBudget
    }
}
