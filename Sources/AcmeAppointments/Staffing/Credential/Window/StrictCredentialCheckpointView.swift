import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a strict credential checkpoint.
    final class StrictCredentialCheckpointView {
        var codeText: String
        var name: String
        var contactEmail: String
        var quantity: String
        var timezone: String
        var wardText: String
        var approved: String
        var statusLabel: String

        init(codeText: String, name: String, contactEmail: String, quantity: String, timezone: String, wardText: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.timezone = timezone
            self.wardText = wardText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCredentialCheckpointView(_ item: StrictCredentialCheckpoint) -> StrictCredentialCheckpointView {
        return StrictCredentialCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            quantity: String(item.quantity),
            timezone: item.timezone,
            wardText: item.ward,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCredentialCheckpointViews(_ items: [StrictCredentialCheckpoint]) -> [StrictCredentialCheckpointView] {
        var views: [StrictCredentialCheckpointView] = []
        for item in items {
            views.append(toStrictCredentialCheckpointView(item))
        }
        return views
    }

    static func sumStrictCredentialCheckpointView(_ view: StrictCredentialCheckpointView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
