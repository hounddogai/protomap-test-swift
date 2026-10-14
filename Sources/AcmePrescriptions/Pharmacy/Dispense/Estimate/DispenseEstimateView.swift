import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense estimate.
    final class DispenseEstimateView {
        var code: String
        var title: String
        var contactEmailText: String
        var patientRef: String
        var checksum: String
        var quantityText: String
        var statusLabel: String

        init(code: String, title: String, contactEmailText: String, patientRef: String, checksum: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmailText = contactEmailText
            self.patientRef = patientRef
            self.checksum = checksum
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseEstimateView(_ item: DispenseEstimate) -> DispenseEstimateView {
        return DispenseEstimateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 80),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            checksum: item.checksum,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseEstimateViews(_ items: [DispenseEstimate]) -> [DispenseEstimateView] {
        var views: [DispenseEstimateView] = []
        for item in items {
            views.append(toDispenseEstimateView(item))
        }
        return views
    }

    static func sumDispenseEstimateView(_ view: DispenseEstimateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
