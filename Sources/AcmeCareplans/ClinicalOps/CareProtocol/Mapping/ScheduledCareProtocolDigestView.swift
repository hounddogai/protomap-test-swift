import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled care protocol digest.
    final class ScheduledCareProtocolDigestView {
        var codeText: String
        var name: String
        var copayText: String
        var encounterID: String
        var updatedAtText: String
        var phoneText: String
        var rate: String
        var labelText: String
        var statusLabel: String

        init(codeText: String, name: String, copayText: String, encounterID: String, updatedAtText: String, phoneText: String, rate: String, labelText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.copayText = copayText
            self.encounterID = encounterID
            self.updatedAtText = updatedAtText
            self.phoneText = phoneText
            self.rate = rate
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareProtocolDigestView(_ item: ScheduledCareProtocolDigest) -> ScheduledCareProtocolDigestView {
        return ScheduledCareProtocolDigestView(
            codeText: item.code,
            name: item.name,
            copayText: String(format: "%.2f", item.copay),
            encounterID: item.encounterID,
            updatedAtText: String(item.updatedAt),
            phoneText: item.phone,
            rate: String(format: "%.2f", item.rate),
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareProtocolDigestViews(_ items: [ScheduledCareProtocolDigest]) -> [ScheduledCareProtocolDigestView] {
        var views: [ScheduledCareProtocolDigestView] = []
        for item in items {
            views.append(toScheduledCareProtocolDigestView(item))
        }
        return views
    }

    static func sumScheduledCareProtocolDigestView(_ view: ScheduledCareProtocolDigestView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCopay + Double(parsedUpdatedAt) + parsedRate
    }
}
