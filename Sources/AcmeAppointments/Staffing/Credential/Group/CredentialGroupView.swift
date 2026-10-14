import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential group.
    final class CredentialGroupView {
        var codeText: String
        var nameText: String
        var bed: String
        var minimum: String
        var channel: String
        var copay: String
        var ownerID: String
        var approvedText: String
        var discount: String
        var locale: String
        var statusLabel: String

        init(codeText: String, nameText: String, bed: String, minimum: String, channel: String, copay: String, ownerID: String, approvedText: String, discount: String, locale: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.bed = bed
            self.minimum = minimum
            self.channel = channel
            self.copay = copay
            self.ownerID = ownerID
            self.approvedText = approvedText
            self.discount = discount
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialGroupView(_ item: CredentialGroup) -> CredentialGroupView {
        return CredentialGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            bed: item.bed,
            minimum: String(format: "%.2f", item.minimum),
            channel: item.channel,
            copay: String(format: "%.2f", item.copay),
            ownerID: item.ownerID,
            approvedText: "\(item.approved)",
            discount: String(format: "%.2f", item.discount),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialGroupViews(_ items: [CredentialGroup]) -> [CredentialGroupView] {
        var views: [CredentialGroupView] = []
        for item in items {
            views.append(toCredentialGroupView(item))
        }
        return views
    }

    static func sumCredentialGroupView(_ view: CredentialGroupView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedMinimum + parsedCopay + parsedDiscount
    }
}
