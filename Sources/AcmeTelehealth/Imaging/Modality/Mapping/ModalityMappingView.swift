import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a modality mapping.
    final class ModalityMappingView {
        var code: String
        var name: String
        var allergy: String
        var endsAt: String
        var scoreText: String
        var facility: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, endsAt: String, scoreText: String, facility: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.endsAt = endsAt
            self.scoreText = scoreText
            self.facility = facility
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toModalityMappingView(_ item: ModalityMapping) -> ModalityMappingView {
        return ModalityMappingView(
            code: item.code,
            name: item.name,
            allergy: item.allergy,
            endsAt: String(item.endsAt),
            scoreText: String(format: "%.2f", item.score),
            facility: item.facility,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toModalityMappingViews(_ items: [ModalityMapping]) -> [ModalityMappingView] {
        var views: [ModalityMappingView] = []
        for item in items {
            views.append(toModalityMappingView(item))
        }
        return views
    }

    static func sumModalityMappingView(_ view: ModalityMappingView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedEndsAt) + parsedScore + parsedAmount
    }
}
