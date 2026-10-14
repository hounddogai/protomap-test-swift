import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped discharge plan item.
    final class CappedDischargePlanItemView {
        var codeText: String
        var name: String
        var region: String
        var reviewerText: String
        var patientRef: String
        var facility: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, region: String, reviewerText: String, patientRef: String, facility: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.region = region
            self.reviewerText = reviewerText
            self.patientRef = patientRef
            self.facility = facility
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDischargePlanItemView(_ item: CappedDischargePlanItem) -> CappedDischargePlanItemView {
        return CappedDischargePlanItemView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            region: item.region,
            reviewerText: item.reviewer,
            patientRef: item.patientRef,
            facility: item.facility,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDischargePlanItemViews(_ items: [CappedDischargePlanItem]) -> [CappedDischargePlanItemView] {
        var views: [CappedDischargePlanItemView] = []
        for item in items {
            views.append(toCappedDischargePlanItemView(item))
        }
        return views
    }

    static func sumCappedDischargePlanItemView(_ view: CappedDischargePlanItemView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
