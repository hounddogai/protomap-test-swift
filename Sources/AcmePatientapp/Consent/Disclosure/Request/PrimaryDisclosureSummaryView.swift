import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary disclosure summary.
    final class PrimaryDisclosureSummaryView {
        var codeText: String
        var nameText: String
        var quantity: String
        var patientRef: String
        var region: String
        var currency: String
        var copay: String
        var weight: String
        var discount: String
        var startsAt: String
        var acuity: String
        var statusLabel: String

        init(codeText: String, nameText: String, quantity: String, patientRef: String, region: String, currency: String, copay: String, weight: String, discount: String, startsAt: String, acuity: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.quantity = quantity
            self.patientRef = patientRef
            self.region = region
            self.currency = currency
            self.copay = copay
            self.weight = weight
            self.discount = discount
            self.startsAt = startsAt
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDisclosureSummaryView(_ item: PrimaryDisclosureSummary) -> PrimaryDisclosureSummaryView {
        return PrimaryDisclosureSummaryView(
            codeText: item.code,
            nameText: item.name,
            quantity: String(item.quantity),
            patientRef: item.patientRef,
            region: Kit.Text.truncate(item.region, limit: 80),
            currency: item.currency,
            copay: String(format: "%.2f", item.copay),
            weight: String(format: "%.2f", item.weight),
            discount: String(format: "%.2f", item.discount),
            startsAt: String(item.startsAt),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDisclosureSummaryViews(_ items: [PrimaryDisclosureSummary]) -> [PrimaryDisclosureSummaryView] {
        var views: [PrimaryDisclosureSummaryView] = []
        for item in items {
            views.append(toPrimaryDisclosureSummaryView(item))
        }
        return views
    }

    static func sumPrimaryDisclosureSummaryView(_ view: PrimaryDisclosureSummaryView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedQuantity) + parsedCopay + parsedWeight
    }
}
