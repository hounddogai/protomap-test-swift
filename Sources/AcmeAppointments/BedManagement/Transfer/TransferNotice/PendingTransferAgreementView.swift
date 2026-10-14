import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending transfer agreement.
    final class PendingTransferAgreementView {
        var code: String
        var name: String
        var sequenceText: String
        var country: String
        var ceiling: String
        var timezone: String
        var encounterID: String
        var channel: String
        var attempts: String
        var budgetText: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, name: String, sequenceText: String, country: String, ceiling: String, timezone: String, encounterID: String, channel: String, attempts: String, budgetText: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequenceText = sequenceText
            self.country = country
            self.ceiling = ceiling
            self.timezone = timezone
            self.encounterID = encounterID
            self.channel = channel
            self.attempts = attempts
            self.budgetText = budgetText
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingTransferAgreementView(_ item: PendingTransferAgreement) -> PendingTransferAgreementView {
        return PendingTransferAgreementView(
            code: item.code,
            name: item.name,
            sequenceText: String(item.sequence),
            country: item.country,
            ceiling: String(format: "%.2f", item.ceiling),
            timezone: item.timezone,
            encounterID: item.encounterID,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            attempts: String(item.attempts),
            budgetText: String(format: "%.2f", item.budget),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingTransferAgreementViews(_ items: [PendingTransferAgreement]) -> [PendingTransferAgreementView] {
        var views: [PendingTransferAgreementView] = []
        for item in items {
            views.append(toPendingTransferAgreementView(item))
        }
        return views
    }

    static func sumPendingTransferAgreementView(_ view: PendingTransferAgreementView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedSequence) + parsedCeiling + Double(parsedAttempts)
    }
}
