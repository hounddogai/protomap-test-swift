import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped specimen quota.
    final class CappedSpecimenQuotaView {
        var code: String
        var label: String
        var patientRef: String
        var segment: String
        var encounterID: String
        var attemptsText: String
        var allergyText: String
        var endsAtText: String
        var discount: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, patientRef: String, segment: String, encounterID: String, attemptsText: String, allergyText: String, endsAtText: String, discount: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.segment = segment
            self.encounterID = encounterID
            self.attemptsText = attemptsText
            self.allergyText = allergyText
            self.endsAtText = endsAtText
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSpecimenQuotaView(_ item: CappedSpecimenQuota) -> CappedSpecimenQuotaView {
        return CappedSpecimenQuotaView(
            code: item.code,
            label: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            segment: item.segment,
            encounterID: item.encounterID,
            attemptsText: String(item.attempts),
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            endsAtText: String(item.endsAt),
            discount: String(format: "%.2f", item.discount),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSpecimenQuotaViews(_ items: [CappedSpecimenQuota]) -> [CappedSpecimenQuotaView] {
        var views: [CappedSpecimenQuotaView] = []
        for item in items {
            views.append(toCappedSpecimenQuotaView(item))
        }
        return views
    }

    static func sumCappedSpecimenQuotaView(_ view: CappedSpecimenQuotaView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedAttempts) + Double(parsedEndsAt) + parsedDiscount
    }
}
