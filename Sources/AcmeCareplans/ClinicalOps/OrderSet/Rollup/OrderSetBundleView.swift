import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set bundle.
    final class OrderSetBundleView {
        var code: String
        var titleText: String
        var approvedText: String
        var patientRef: String
        var name: String
        var externalRef: String
        var quantity: String
        var floorValueText: String
        var contactEmail: String
        var attempts: String
        var statusLabel: String

        init(code: String, titleText: String, approvedText: String, patientRef: String, name: String, externalRef: String, quantity: String, floorValueText: String, contactEmail: String, attempts: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approvedText = approvedText
            self.patientRef = patientRef
            self.name = name
            self.externalRef = externalRef
            self.quantity = quantity
            self.floorValueText = floorValueText
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetBundleView(_ item: OrderSetBundle) -> OrderSetBundleView {
        return OrderSetBundleView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            approvedText: "\(item.approved)",
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            name: item.name,
            externalRef: item.externalRef,
            quantity: String(item.quantity),
            floorValueText: String(format: "%.2f", item.floorValue),
            contactEmail: item.contactEmail,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetBundleViews(_ items: [OrderSetBundle]) -> [OrderSetBundleView] {
        var views: [OrderSetBundleView] = []
        for item in items {
            views.append(toOrderSetBundleView(item))
        }
        return views
    }

    static func sumOrderSetBundleView(_ view: OrderSetBundleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedQuantity) + parsedFloorValue + Double(parsedAttempts)
    }
}
