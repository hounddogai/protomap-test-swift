import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling worklist adjustment.
    final class RollingWorklistAdjustmentView {
        var code: String
        var title: String
        var copay: String
        var contactEmail: String
        var bedText: String
        var discount: String
        var threshold: String
        var quantityText: String
        var unit: String
        var reviewer: String
        var facilityText: String
        var statusLabel: String

        init(code: String, title: String, copay: String, contactEmail: String, bedText: String, discount: String, threshold: String, quantityText: String, unit: String, reviewer: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.copay = copay
            self.contactEmail = contactEmail
            self.bedText = bedText
            self.discount = discount
            self.threshold = threshold
            self.quantityText = quantityText
            self.unit = unit
            self.reviewer = reviewer
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingWorklistAdjustmentView(_ item: RollingWorklistAdjustment) -> RollingWorklistAdjustmentView {
        return RollingWorklistAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 64),
            copay: String(format: "%.2f", item.copay),
            contactEmail: item.contactEmail,
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            discount: String(format: "%.2f", item.discount),
            threshold: String(format: "%.2f", item.threshold),
            quantityText: String(item.quantity),
            unit: Kit.Text.truncate(item.unit, limit: 64),
            reviewer: item.reviewer,
            facilityText: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingWorklistAdjustmentViews(_ items: [RollingWorklistAdjustment]) -> [RollingWorklistAdjustmentView] {
        var views: [RollingWorklistAdjustmentView] = []
        for item in items {
            views.append(toRollingWorklistAdjustmentView(item))
        }
        return views
    }

    static func sumRollingWorklistAdjustmentView(_ view: RollingWorklistAdjustmentView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCopay + parsedDiscount + parsedThreshold
    }
}
