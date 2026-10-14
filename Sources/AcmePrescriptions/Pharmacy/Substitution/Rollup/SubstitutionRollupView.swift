import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution rollup.
    final class SubstitutionRollupView {
        var code: String
        var nameText: String
        var procedureCodeText: String
        var updatedAt: String
        var createdAt: String
        var archivedText: String
        var margin: String
        var unit: String
        var bedText: String
        var statusLabel: String

        init(code: String, nameText: String, procedureCodeText: String, updatedAt: String, createdAt: String, archivedText: String, margin: String, unit: String, bedText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.procedureCodeText = procedureCodeText
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.archivedText = archivedText
            self.margin = margin
            self.unit = unit
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionRollupView(_ item: SubstitutionRollup) -> SubstitutionRollupView {
        return SubstitutionRollupView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            procedureCodeText: item.procedureCode,
            updatedAt: String(item.updatedAt),
            createdAt: String(item.createdAt),
            archivedText: "\(item.archived)",
            margin: String(format: "%.2f", item.margin),
            unit: item.unit,
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionRollupViews(_ items: [SubstitutionRollup]) -> [SubstitutionRollupView] {
        var views: [SubstitutionRollupView] = []
        for item in items {
            views.append(toSubstitutionRollupView(item))
        }
        return views
    }

    static func sumSubstitutionRollupView(_ view: SubstitutionRollupView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCreatedAt) + parsedMargin
    }
}
