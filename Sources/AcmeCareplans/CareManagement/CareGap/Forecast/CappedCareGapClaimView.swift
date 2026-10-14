import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped care gap claim.
    final class CappedCareGapClaimView {
        var codeText: String
        var label: String
        var dosageMgText: String
        var discount: String
        var archived: String
        var pinned: String
        var timezone: String
        var quantity: String
        var diagnosisCodeText: String
        var locale: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMgText: String, discount: String, archived: String, pinned: String, timezone: String, quantity: String, diagnosisCodeText: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMgText = dosageMgText
            self.discount = discount
            self.archived = archived
            self.pinned = pinned
            self.timezone = timezone
            self.quantity = quantity
            self.diagnosisCodeText = diagnosisCodeText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCareGapClaimView(_ item: CappedCareGapClaim) -> CappedCareGapClaimView {
        return CappedCareGapClaimView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            discount: String(format: "%.2f", item.discount),
            archived: "\(item.archived)",
            pinned: "\(item.pinned)",
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            quantity: String(item.quantity),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCareGapClaimViews(_ items: [CappedCareGapClaim]) -> [CappedCareGapClaimView] {
        var views: [CappedCareGapClaimView] = []
        for item in items {
            views.append(toCappedCareGapClaimView(item))
        }
        return views
    }

    static func sumCappedCareGapClaimView(_ view: CappedCareGapClaimView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedDosageMg + parsedDiscount + Double(parsedQuantity)
    }
}
