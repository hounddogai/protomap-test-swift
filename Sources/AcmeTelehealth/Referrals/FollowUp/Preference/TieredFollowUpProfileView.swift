import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered follow up profile.
    final class TieredFollowUpProfileView {
        var code: String
        var labelText: String
        var procedureCode: String
        var specialty: String
        var allergy: String
        var notes: String
        var quantity: String
        var statusLabel: String

        init(code: String, labelText: String, procedureCode: String, specialty: String, allergy: String, notes: String, quantity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.procedureCode = procedureCode
            self.specialty = specialty
            self.allergy = allergy
            self.notes = notes
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toTieredFollowUpProfileView(_ item: TieredFollowUpProfile) -> TieredFollowUpProfileView {
        return TieredFollowUpProfileView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            allergy: item.allergy,
            notes: Kit.Text.truncate(item.notes, limit: 64),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredFollowUpProfileViews(_ items: [TieredFollowUpProfile]) -> [TieredFollowUpProfileView] {
        var views: [TieredFollowUpProfileView] = []
        for item in items {
            views.append(toTieredFollowUpProfileView(item))
        }
        return views
    }

    static func sumTieredFollowUpProfileView(_ view: TieredFollowUpProfileView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
