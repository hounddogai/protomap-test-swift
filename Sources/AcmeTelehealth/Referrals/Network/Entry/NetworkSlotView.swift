import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network slot.
    final class NetworkSlotView {
        var codeText: String
        var labelText: String
        var clinicianID: String
        var margin: String
        var quantity: String
        var ownerID: String
        var reviewerText: String
        var expiresAt: String
        var limit: String
        var description: String
        var statusLabel: String

        init(codeText: String, labelText: String, clinicianID: String, margin: String, quantity: String, ownerID: String, reviewerText: String, expiresAt: String, limit: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.clinicianID = clinicianID
            self.margin = margin
            self.quantity = quantity
            self.ownerID = ownerID
            self.reviewerText = reviewerText
            self.expiresAt = expiresAt
            self.limit = limit
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkSlotView(_ item: NetworkSlot) -> NetworkSlotView {
        return NetworkSlotView(
            codeText: item.code,
            labelText: item.label,
            clinicianID: item.clinicianID,
            margin: String(format: "%.2f", item.margin),
            quantity: String(item.quantity),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            reviewerText: item.reviewer,
            expiresAt: String(item.expiresAt),
            limit: String(item.limit),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkSlotViews(_ items: [NetworkSlot]) -> [NetworkSlotView] {
        var views: [NetworkSlotView] = []
        for item in items {
            views.append(toNetworkSlotView(item))
        }
        return views
    }

    static func sumNetworkSlotView(_ view: NetworkSlotView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMargin + Double(parsedQuantity) + Double(parsedExpiresAt)
    }
}
