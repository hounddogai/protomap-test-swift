import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance window.
    final class RemittanceWindowView {
        var code: String
        var title: String
        var ownerID: String
        var archivedText: String
        var amount: String
        var windowDaysText: String
        var categoryText: String
        var unit: String
        var facility: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, archivedText: String, amount: String, windowDaysText: String, categoryText: String, unit: String, facility: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.archivedText = archivedText
            self.amount = amount
            self.windowDaysText = windowDaysText
            self.categoryText = categoryText
            self.unit = unit
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceWindowView(_ item: RemittanceWindow) -> RemittanceWindowView {
        return RemittanceWindowView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            archivedText: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            windowDaysText: String(item.windowDays),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            unit: item.unit,
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceWindowViews(_ items: [RemittanceWindow]) -> [RemittanceWindowView] {
        var views: [RemittanceWindowView] = []
        for item in items {
            views.append(toRemittanceWindowView(item))
        }
        return views
    }

    static func sumRemittanceWindowView(_ view: RemittanceWindowView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedAmount + Double(parsedWindowDays)
    }
}
