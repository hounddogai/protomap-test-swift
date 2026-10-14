import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending inventory request.
    final class PendingInventoryRequestView {
        var codeText: String
        var titleText: String
        var country: String
        var createdAt: String
        var rateText: String
        var dosageMg: String
        var discountText: String
        var weightText: String
        var statusLabel: String

        init(codeText: String, titleText: String, country: String, createdAt: String, rateText: String, dosageMg: String, discountText: String, weightText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.country = country
            self.createdAt = createdAt
            self.rateText = rateText
            self.dosageMg = dosageMg
            self.discountText = discountText
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingInventoryRequestView(_ item: PendingInventoryRequest) -> PendingInventoryRequestView {
        return PendingInventoryRequestView(
            codeText: item.code,
            titleText: item.title,
            country: item.country,
            createdAt: String(item.createdAt),
            rateText: String(format: "%.2f", item.rate),
            dosageMg: String(format: "%.2f", item.dosageMg),
            discountText: String(format: "%.2f", item.discount),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingInventoryRequestViews(_ items: [PendingInventoryRequest]) -> [PendingInventoryRequestView] {
        var views: [PendingInventoryRequestView] = []
        for item in items {
            views.append(toPendingInventoryRequestView(item))
        }
        return views
    }

    static func sumPendingInventoryRequestView(_ view: PendingInventoryRequestView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCreatedAt) + parsedRate + parsedDosageMg
    }
}
