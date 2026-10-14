import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal worklist assignment.
    final class SeasonalWorklistAssignmentView {
        var code: String
        var label: String
        var pinnedText: String
        var bed: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, pinnedText: String, bed: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.pinnedText = pinnedText
            self.bed = bed
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalWorklistAssignmentView(_ item: SeasonalWorklistAssignment) -> SeasonalWorklistAssignmentView {
        return SeasonalWorklistAssignmentView(
            code: item.code,
            label: item.label,
            pinnedText: "\(item.pinned)",
            bed: item.bed,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalWorklistAssignmentViews(_ items: [SeasonalWorklistAssignment]) -> [SeasonalWorklistAssignmentView] {
        var views: [SeasonalWorklistAssignmentView] = []
        for item in items {
            views.append(toSeasonalWorklistAssignmentView(item))
        }
        return views
    }

    static func sumSeasonalWorklistAssignmentView(_ view: SeasonalWorklistAssignmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
