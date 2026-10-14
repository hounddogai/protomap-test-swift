import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted recall draft.
    final class WeightedRecallDraftView {
        var code: String
        var nameText: String
        var label: String
        var ratio: String
        var capacityText: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, nameText: String, label: String, ratio: String, capacityText: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.label = label
            self.ratio = ratio
            self.capacityText = capacityText
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRecallDraftView(_ item: WeightedRecallDraft) -> WeightedRecallDraftView {
        return WeightedRecallDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            capacityText: String(item.capacity),
            clinicianID: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRecallDraftViews(_ items: [WeightedRecallDraft]) -> [WeightedRecallDraftView] {
        var views: [WeightedRecallDraftView] = []
        for item in items {
            views.append(toWeightedRecallDraftView(item))
        }
        return views
    }

    static func sumWeightedRecallDraftView(_ view: WeightedRecallDraftView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedRatio + Double(parsedCapacity)
    }
}
