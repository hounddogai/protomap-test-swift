import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory variance.
    final class InventoryVarianceView {
        var code: String
        var title: String
        var expiresAt: String
        var active: String
        var ownerID: String
        var refillsText: String
        var ward: String
        var payer: String
        var notes: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, expiresAt: String, active: String, ownerID: String, refillsText: String, ward: String, payer: String, notes: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.active = active
            self.ownerID = ownerID
            self.refillsText = refillsText
            self.ward = ward
            self.payer = payer
            self.notes = notes
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryVarianceView(_ item: InventoryVariance) -> InventoryVarianceView {
        return InventoryVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 64),
            expiresAt: String(item.expiresAt),
            active: "\(item.active)",
            ownerID: item.ownerID,
            refillsText: String(item.refills),
            ward: Kit.Text.truncate(item.ward, limit: 80),
            payer: item.payer,
            notes: item.notes,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryVarianceViews(_ items: [InventoryVariance]) -> [InventoryVarianceView] {
        var views: [InventoryVarianceView] = []
        for item in items {
            views.append(toInventoryVarianceView(item))
        }
        return views
    }

    static func sumInventoryVarianceView(_ view: InventoryVarianceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedRefills)
    }
}
