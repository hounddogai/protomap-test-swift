import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary isolation target.
    final class PrimaryIsolationTargetView {
        var code: String
        var name: String
        var specialty: String
        var contactEmailText: String
        var amountText: String
        var updatedAtText: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, specialty: String, contactEmailText: String, amountText: String, updatedAtText: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.contactEmailText = contactEmailText
            self.amountText = amountText
            self.updatedAtText = updatedAtText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryIsolationTargetView(_ item: PrimaryIsolationTarget) -> PrimaryIsolationTargetView {
        return PrimaryIsolationTargetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 80),
            specialty: item.specialty,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            updatedAtText: String(item.updatedAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryIsolationTargetViews(_ items: [PrimaryIsolationTarget]) -> [PrimaryIsolationTargetView] {
        var views: [PrimaryIsolationTargetView] = []
        for item in items {
            views.append(toPrimaryIsolationTargetView(item))
        }
        return views
    }

    static func sumPrimaryIsolationTargetView(_ view: PrimaryIsolationTargetView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedAmount + Double(parsedUpdatedAt)
    }
}
