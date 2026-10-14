import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted modality profile.
    final class WeightedModalityProfileView {
        var code: String
        var name: String
        var pinnedText: String
        var limit: String
        var clinicianID: String
        var allergyText: String
        var minimumText: String
        var budget: String
        var expiresAtText: String
        var approved: String
        var copayText: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, limit: String, clinicianID: String, allergyText: String, minimumText: String, budget: String, expiresAtText: String, approved: String, copayText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.limit = limit
            self.clinicianID = clinicianID
            self.allergyText = allergyText
            self.minimumText = minimumText
            self.budget = budget
            self.expiresAtText = expiresAtText
            self.approved = approved
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedModalityProfileView(_ item: WeightedModalityProfile) -> WeightedModalityProfileView {
        return WeightedModalityProfileView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            pinnedText: "\(item.pinned)",
            limit: String(item.limit),
            clinicianID: item.clinicianID,
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            minimumText: String(format: "%.2f", item.minimum),
            budget: String(format: "%.2f", item.budget),
            expiresAtText: String(item.expiresAt),
            approved: "\(item.approved)",
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedModalityProfileViews(_ items: [WeightedModalityProfile]) -> [WeightedModalityProfileView] {
        var views: [WeightedModalityProfileView] = []
        for item in items {
            views.append(toWeightedModalityProfileView(item))
        }
        return views
    }

    static func sumWeightedModalityProfileView(_ view: WeightedModalityProfileView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedLimit) + parsedMinimum + parsedBudget
    }
}
