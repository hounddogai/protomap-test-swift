import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read exception.
    final class ReadExceptionView {
        var code: String
        var label: String
        var weight: String
        var priorityText: String
        var clinicianID: String
        var country: String
        var payer: String
        var quantity: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, weight: String, priorityText: String, clinicianID: String, country: String, payer: String, quantity: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.priorityText = priorityText
            self.clinicianID = clinicianID
            self.country = country
            self.payer = payer
            self.quantity = quantity
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toReadExceptionView(_ item: ReadException) -> ReadExceptionView {
        return ReadExceptionView(
            code: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            priorityText: String(item.priority),
            clinicianID: item.clinicianID,
            country: item.country,
            payer: Kit.Text.truncate(item.payer, limit: 120),
            quantity: String(item.quantity),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadExceptionViews(_ items: [ReadException]) -> [ReadExceptionView] {
        var views: [ReadExceptionView] = []
        for item in items {
            views.append(toReadExceptionView(item))
        }
        return views
    }

    static func sumReadExceptionView(_ view: ReadExceptionView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedWeight + Double(parsedPriority) + Double(parsedQuantity)
    }
}
