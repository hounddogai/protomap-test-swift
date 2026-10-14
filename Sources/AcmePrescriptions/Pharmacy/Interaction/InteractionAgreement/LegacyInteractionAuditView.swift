import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy interaction audit.
    final class LegacyInteractionAuditView {
        var code: String
        var name: String
        var channel: String
        var notes: String
        var category: String
        var retries: String
        var weightText: String
        var checksumText: String
        var specialty: String
        var capacityText: String
        var statusLabel: String

        init(code: String, name: String, channel: String, notes: String, category: String, retries: String, weightText: String, checksumText: String, specialty: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.channel = channel
            self.notes = notes
            self.category = category
            self.retries = retries
            self.weightText = weightText
            self.checksumText = checksumText
            self.specialty = specialty
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInteractionAuditView(_ item: LegacyInteractionAudit) -> LegacyInteractionAuditView {
        return LegacyInteractionAuditView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            channel: item.channel,
            notes: item.notes,
            category: Kit.Text.truncate(item.category, limit: 40),
            retries: String(item.retries),
            weightText: String(format: "%.2f", item.weight),
            checksumText: Kit.Text.truncate(item.checksum, limit: 64),
            specialty: item.specialty,
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInteractionAuditViews(_ items: [LegacyInteractionAudit]) -> [LegacyInteractionAuditView] {
        var views: [LegacyInteractionAuditView] = []
        for item in items {
            views.append(toLegacyInteractionAuditView(item))
        }
        return views
    }

    static func sumLegacyInteractionAuditView(_ view: LegacyInteractionAuditView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedRetries) + parsedWeight + Double(parsedCapacity)
    }
}
