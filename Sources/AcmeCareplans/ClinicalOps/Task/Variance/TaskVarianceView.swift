import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task variance.
    final class TaskVarianceView {
        var code: String
        var titleText: String
        var pinnedText: String
        var encounterIDText: String
        var bed: String
        var allergyText: String
        var quantityText: String
        var statusLabel: String

        init(code: String, titleText: String, pinnedText: String, encounterIDText: String, bed: String, allergyText: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.pinnedText = pinnedText
            self.encounterIDText = encounterIDText
            self.bed = bed
            self.allergyText = allergyText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toTaskVarianceView(_ item: TaskVariance) -> TaskVarianceView {
        return TaskVarianceView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            pinnedText: "\(item.pinned)",
            encounterIDText: item.encounterID,
            bed: item.bed,
            allergyText: Kit.Text.truncate(item.allergy, limit: 120),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskVarianceViews(_ items: [TaskVariance]) -> [TaskVarianceView] {
        var views: [TaskVarianceView] = []
        for item in items {
            views.append(toTaskVarianceView(item))
        }
        return views
    }

    static func sumTaskVarianceView(_ view: TaskVarianceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
