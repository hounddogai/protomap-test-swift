import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped eligibility slot.
    final class CappedEligibilitySlotView {
        var codeText: String
        var titleText: String
        var payerText: String
        var ownerID: String
        var copay: String
        var contactEmailText: String
        var durationMinutesText: String
        var batchSize: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, titleText: String, payerText: String, ownerID: String, copay: String, contactEmailText: String, durationMinutesText: String, batchSize: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.payerText = payerText
            self.ownerID = ownerID
            self.copay = copay
            self.contactEmailText = contactEmailText
            self.durationMinutesText = durationMinutesText
            self.batchSize = batchSize
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toCappedEligibilitySlotView(_ item: CappedEligibilitySlot) -> CappedEligibilitySlotView {
        return CappedEligibilitySlotView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 120),
            payerText: item.payer,
            ownerID: item.ownerID,
            copay: String(format: "%.2f", item.copay),
            contactEmailText: item.contactEmail,
            durationMinutesText: String(item.durationMinutes),
            batchSize: String(item.batchSize),
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedEligibilitySlotViews(_ items: [CappedEligibilitySlot]) -> [CappedEligibilitySlotView] {
        var views: [CappedEligibilitySlotView] = []
        for item in items {
            views.append(toCappedEligibilitySlotView(item))
        }
        return views
    }

    static func sumCappedEligibilitySlotView(_ view: CappedEligibilitySlotView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes) + Double(parsedBatchSize)
    }
}
