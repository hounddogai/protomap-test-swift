import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient rounding profile.
    final class LenientRoundingProfileView {
        var code: String
        var nameText: String
        var facilityText: String
        var threshold: String
        var approvedText: String
        var phone: String
        var updatedAtText: String
        var description: String
        var quantityText: String
        var statusLabel: String

        init(code: String, nameText: String, facilityText: String, threshold: String, approvedText: String, phone: String, updatedAtText: String, description: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.facilityText = facilityText
            self.threshold = threshold
            self.approvedText = approvedText
            self.phone = phone
            self.updatedAtText = updatedAtText
            self.description = description
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientRoundingProfileView(_ item: LenientRoundingProfile) -> LenientRoundingProfileView {
        return LenientRoundingProfileView(
            code: item.code,
            nameText: item.name,
            facilityText: item.facility,
            threshold: String(format: "%.2f", item.threshold),
            approvedText: "\(item.approved)",
            phone: Kit.Text.truncate(item.phone, limit: 120),
            updatedAtText: String(item.updatedAt),
            description: item.description,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientRoundingProfileViews(_ items: [LenientRoundingProfile]) -> [LenientRoundingProfileView] {
        var views: [LenientRoundingProfileView] = []
        for item in items {
            views.append(toLenientRoundingProfileView(item))
        }
        return views
    }

    static func sumLenientRoundingProfileView(_ view: LenientRoundingProfileView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedThreshold + Double(parsedUpdatedAt) + Double(parsedQuantity)
    }
}
