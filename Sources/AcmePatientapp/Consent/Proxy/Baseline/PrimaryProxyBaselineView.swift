import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary proxy baseline.
    final class PrimaryProxyBaselineView {
        var codeText: String
        var name: String
        var ownerID: String
        var procedureCode: String
        var durationMinutes: String
        var phoneText: String
        var encounterID: String
        var channel: String
        var statusLabel: String

        init(codeText: String, name: String, ownerID: String, procedureCode: String, durationMinutes: String, phoneText: String, encounterID: String, channel: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ownerID = ownerID
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.phoneText = phoneText
            self.encounterID = encounterID
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryProxyBaselineView(_ item: PrimaryProxyBaseline) -> PrimaryProxyBaselineView {
        return PrimaryProxyBaselineView(
            codeText: item.code,
            name: item.name,
            ownerID: item.ownerID,
            procedureCode: item.procedureCode,
            durationMinutes: String(item.durationMinutes),
            phoneText: item.phone,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryProxyBaselineViews(_ items: [PrimaryProxyBaseline]) -> [PrimaryProxyBaselineView] {
        var views: [PrimaryProxyBaselineView] = []
        for item in items {
            views.append(toPrimaryProxyBaselineView(item))
        }
        return views
    }

    static func sumPrimaryProxyBaselineView(_ view: PrimaryProxyBaselineView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
