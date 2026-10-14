import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary discharge plan baseline.
    final class PrimaryDischargePlanBaselineView {
        var codeText: String
        var title: String
        var quantity: String
        var name: String
        var capacity: String
        var phone: String
        var patientRefText: String
        var statusLabel: String

        init(codeText: String, title: String, quantity: String, name: String, capacity: String, phone: String, patientRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.quantity = quantity
            self.name = name
            self.capacity = capacity
            self.phone = phone
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDischargePlanBaselineView(_ item: PrimaryDischargePlanBaseline) -> PrimaryDischargePlanBaselineView {
        return PrimaryDischargePlanBaselineView(
            codeText: item.code,
            title: item.title,
            quantity: String(item.quantity),
            name: item.name,
            capacity: String(item.capacity),
            phone: item.phone,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDischargePlanBaselineViews(_ items: [PrimaryDischargePlanBaseline]) -> [PrimaryDischargePlanBaselineView] {
        var views: [PrimaryDischargePlanBaselineView] = []
        for item in items {
            views.append(toPrimaryDischargePlanBaselineView(item))
        }
        return views
    }

    static func sumPrimaryDischargePlanBaselineView(_ view: PrimaryDischargePlanBaselineView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedQuantity) + Double(parsedCapacity)
    }
}
