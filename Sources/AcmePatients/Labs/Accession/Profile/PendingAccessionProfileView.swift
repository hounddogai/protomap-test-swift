import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending accession profile.
    final class PendingAccessionProfileView {
        var code: String
        var title: String
        var pinned: String
        var segment: String
        var specialty: String
        var payer: String
        var amount: String
        var facility: String
        var updatedAt: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, pinned: String, segment: String, specialty: String, payer: String, amount: String, facility: String, updatedAt: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.segment = segment
            self.specialty = specialty
            self.payer = payer
            self.amount = amount
            self.facility = facility
            self.updatedAt = updatedAt
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAccessionProfileView(_ item: PendingAccessionProfile) -> PendingAccessionProfileView {
        return PendingAccessionProfileView(
            code: item.code,
            title: item.title,
            pinned: "\(item.pinned)",
            segment: Kit.Text.truncate(item.segment, limit: 64),
            specialty: item.specialty,
            payer: item.payer,
            amount: String(format: "%.2f", item.amount),
            facility: item.facility,
            updatedAt: String(item.updatedAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAccessionProfileViews(_ items: [PendingAccessionProfile]) -> [PendingAccessionProfileView] {
        var views: [PendingAccessionProfileView] = []
        for item in items {
            views.append(toPendingAccessionProfileView(item))
        }
        return views
    }

    static func sumPendingAccessionProfileView(_ view: PendingAccessionProfileView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedAmount + Double(parsedUpdatedAt)
    }
}
