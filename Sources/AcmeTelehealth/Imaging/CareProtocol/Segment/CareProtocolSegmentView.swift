import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol segment.
    final class CareProtocolSegmentView {
        var codeText: String
        var name: String
        var quantity: String
        var clinicianID: String
        var discount: String
        var localeText: String
        var budget: String
        var externalRef: String
        var priority: String
        var statusLabel: String

        init(codeText: String, name: String, quantity: String, clinicianID: String, discount: String, localeText: String, budget: String, externalRef: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.discount = discount
            self.localeText = localeText
            self.budget = budget
            self.externalRef = externalRef
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolSegmentView(_ item: CareProtocolSegment) -> CareProtocolSegmentView {
        return CareProtocolSegmentView(
            codeText: item.code,
            name: item.name,
            quantity: String(item.quantity),
            clinicianID: item.clinicianID,
            discount: String(format: "%.2f", item.discount),
            localeText: item.locale,
            budget: String(format: "%.2f", item.budget),
            externalRef: item.externalRef,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolSegmentViews(_ items: [CareProtocolSegment]) -> [CareProtocolSegmentView] {
        var views: [CareProtocolSegmentView] = []
        for item in items {
            views.append(toCareProtocolSegmentView(item))
        }
        return views
    }

    static func sumCareProtocolSegmentView(_ view: CareProtocolSegmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedQuantity) + parsedDiscount + parsedBudget
    }
}
