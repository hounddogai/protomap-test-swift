import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier batch.
    final class CourierBatchView {
        var code: String
        var labelText: String
        var revisionText: String
        var notesText: String
        var active: String
        var payerText: String
        var capacityText: String
        var expiresAt: String
        var discountText: String
        var description: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, labelText: String, revisionText: String, notesText: String, active: String, payerText: String, capacityText: String, expiresAt: String, discountText: String, description: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.revisionText = revisionText
            self.notesText = notesText
            self.active = active
            self.payerText = payerText
            self.capacityText = capacityText
            self.expiresAt = expiresAt
            self.discountText = discountText
            self.description = description
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierBatchView(_ item: CourierBatch) -> CourierBatchView {
        return CourierBatchView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            revisionText: String(item.revision),
            notesText: Kit.Text.truncate(item.notes, limit: 40),
            active: "\(item.active)",
            payerText: Kit.Text.truncate(item.payer, limit: 120),
            capacityText: String(item.capacity),
            expiresAt: String(item.expiresAt),
            discountText: String(format: "%.2f", item.discount),
            description: Kit.Text.truncate(item.description, limit: 120),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierBatchViews(_ items: [CourierBatch]) -> [CourierBatchView] {
        var views: [CourierBatchView] = []
        for item in items {
            views.append(toCourierBatchView(item))
        }
        return views
    }

    static func sumCourierBatchView(_ view: CourierBatchView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRevision) + Double(parsedCapacity) + Double(parsedExpiresAt)
    }
}
