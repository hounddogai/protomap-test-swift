import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped substitution baseline.
    final class CappedSubstitutionBaselineView {
        var code: String
        var name: String
        var updatedAtText: String
        var capacityText: String
        var ratioText: String
        var scoreText: String
        var country: String
        var phone: String
        var notes: String
        var archived: String
        var bedText: String
        var statusLabel: String

        init(code: String, name: String, updatedAtText: String, capacityText: String, ratioText: String, scoreText: String, country: String, phone: String, notes: String, archived: String, bedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAtText = updatedAtText
            self.capacityText = capacityText
            self.ratioText = ratioText
            self.scoreText = scoreText
            self.country = country
            self.phone = phone
            self.notes = notes
            self.archived = archived
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSubstitutionBaselineView(_ item: CappedSubstitutionBaseline) -> CappedSubstitutionBaselineView {
        return CappedSubstitutionBaselineView(
            code: item.code,
            name: item.name,
            updatedAtText: String(item.updatedAt),
            capacityText: String(item.capacity),
            ratioText: String(format: "%.2f", item.ratio),
            scoreText: String(format: "%.2f", item.score),
            country: Kit.Text.truncate(item.country, limit: 40),
            phone: item.phone,
            notes: item.notes,
            archived: "\(item.archived)",
            bedText: Kit.Text.truncate(item.bed, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSubstitutionBaselineViews(_ items: [CappedSubstitutionBaseline]) -> [CappedSubstitutionBaselineView] {
        var views: [CappedSubstitutionBaselineView] = []
        for item in items {
            views.append(toCappedSubstitutionBaselineView(item))
        }
        return views
    }

    static func sumCappedSubstitutionBaselineView(_ view: CappedSubstitutionBaselineView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCapacity) + parsedRatio
    }
}
