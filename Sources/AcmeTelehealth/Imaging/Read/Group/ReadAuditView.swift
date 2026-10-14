import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read audit.
    final class ReadAuditView {
        var codeText: String
        var label: String
        var expiresAt: String
        var encounterID: String
        var quantity: String
        var titleText: String
        var maximum: String
        var pinned: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, label: String, expiresAt: String, encounterID: String, quantity: String, titleText: String, maximum: String, pinned: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.expiresAt = expiresAt
            self.encounterID = encounterID
            self.quantity = quantity
            self.titleText = titleText
            self.maximum = maximum
            self.pinned = pinned
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toReadAuditView(_ item: ReadAudit) -> ReadAuditView {
        return ReadAuditView(
            codeText: item.code,
            label: item.label,
            expiresAt: String(item.expiresAt),
            encounterID: item.encounterID,
            quantity: String(item.quantity),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            pinned: "\(item.pinned)",
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadAuditViews(_ items: [ReadAudit]) -> [ReadAuditView] {
        var views: [ReadAuditView] = []
        for item in items {
            views.append(toReadAuditView(item))
        }
        return views
    }

    static func sumReadAuditView(_ view: ReadAuditView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedQuantity) + parsedMaximum
    }
}
