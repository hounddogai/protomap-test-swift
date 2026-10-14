import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary priority profile.
    final class PrimaryPriorityProfileView {
        var codeText: String
        var nameText: String
        var clinicianIDText: String
        var quantityText: String
        var ceilingText: String
        var windowDays: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, nameText: String, clinicianIDText: String, quantityText: String, ceilingText: String, windowDays: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.clinicianIDText = clinicianIDText
            self.quantityText = quantityText
            self.ceilingText = ceilingText
            self.windowDays = windowDays
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryPriorityProfileView(_ item: PrimaryPriorityProfile) -> PrimaryPriorityProfileView {
        return PrimaryPriorityProfileView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            clinicianIDText: item.clinicianID,
            quantityText: String(item.quantity),
            ceilingText: String(format: "%.2f", item.ceiling),
            windowDays: String(item.windowDays),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryPriorityProfileViews(_ items: [PrimaryPriorityProfile]) -> [PrimaryPriorityProfileView] {
        var views: [PrimaryPriorityProfileView] = []
        for item in items {
            views.append(toPrimaryPriorityProfileView(item))
        }
        return views
    }

    static func sumPrimaryPriorityProfileView(_ view: PrimaryPriorityProfileView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedQuantity) + parsedCeiling + Double(parsedWindowDays)
    }
}
