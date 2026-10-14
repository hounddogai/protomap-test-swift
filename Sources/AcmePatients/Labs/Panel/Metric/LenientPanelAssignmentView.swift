import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient panel assignment.
    final class LenientPanelAssignmentView {
        var code: String
        var name: String
        var country: String
        var payer: String
        var weight: String
        var statusLabel: String

        init(code: String, name: String, country: String, payer: String, weight: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.country = country
            self.payer = payer
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toLenientPanelAssignmentView(_ item: LenientPanelAssignment) -> LenientPanelAssignmentView {
        return LenientPanelAssignmentView(
            code: item.code,
            name: item.name,
            country: item.country,
            payer: item.payer,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientPanelAssignmentViews(_ items: [LenientPanelAssignment]) -> [LenientPanelAssignmentView] {
        var views: [LenientPanelAssignmentView] = []
        for item in items {
            views.append(toLenientPanelAssignmentView(item))
        }
        return views
    }

    static func sumLenientPanelAssignmentView(_ view: LenientPanelAssignmentView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
