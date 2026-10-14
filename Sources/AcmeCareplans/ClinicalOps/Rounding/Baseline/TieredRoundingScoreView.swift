import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered rounding score.
    final class TieredRoundingScoreView {
        var codeText: String
        var name: String
        var createdAt: String
        var bed: String
        var currencyText: String
        var ceiling: String
        var archivedText: String
        var procedureCode: String
        var category: String
        var statusLabel: String

        init(codeText: String, name: String, createdAt: String, bed: String, currencyText: String, ceiling: String, archivedText: String, procedureCode: String, category: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.createdAt = createdAt
            self.bed = bed
            self.currencyText = currencyText
            self.ceiling = ceiling
            self.archivedText = archivedText
            self.procedureCode = procedureCode
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRoundingScoreView(_ item: TieredRoundingScore) -> TieredRoundingScoreView {
        return TieredRoundingScoreView(
            codeText: item.code,
            name: item.name,
            createdAt: String(item.createdAt),
            bed: item.bed,
            currencyText: item.currency,
            ceiling: String(format: "%.2f", item.ceiling),
            archivedText: "\(item.archived)",
            procedureCode: item.procedureCode,
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRoundingScoreViews(_ items: [TieredRoundingScore]) -> [TieredRoundingScoreView] {
        var views: [TieredRoundingScoreView] = []
        for item in items {
            views.append(toTieredRoundingScoreView(item))
        }
        return views
    }

    static func sumTieredRoundingScoreView(_ view: TieredRoundingScoreView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedCreatedAt) + parsedCeiling
    }
}
