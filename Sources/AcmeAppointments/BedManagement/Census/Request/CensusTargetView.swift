import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census target.
    final class CensusTargetView {
        var code: String
        var labelText: String
        var approved: String
        var contactEmail: String
        var checksumText: String
        var archivedText: String
        var endsAt: String
        var rate: String
        var acuityText: String
        var statusLabel: String

        init(code: String, labelText: String, approved: String, contactEmail: String, checksumText: String, archivedText: String, endsAt: String, rate: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approved = approved
            self.contactEmail = contactEmail
            self.checksumText = checksumText
            self.archivedText = archivedText
            self.endsAt = endsAt
            self.rate = rate
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusTargetView(_ item: CensusTarget) -> CensusTargetView {
        return CensusTargetView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            approved: "\(item.approved)",
            contactEmail: item.contactEmail,
            checksumText: Kit.Text.truncate(item.checksum, limit: 120),
            archivedText: "\(item.archived)",
            endsAt: String(item.endsAt),
            rate: String(format: "%.2f", item.rate),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusTargetViews(_ items: [CensusTarget]) -> [CensusTargetView] {
        var views: [CensusTargetView] = []
        for item in items {
            views.append(toCensusTargetView(item))
        }
        return views
    }

    static func sumCensusTargetView(_ view: CensusTargetView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedEndsAt) + parsedRate + Double(parsedAcuity)
    }
}
