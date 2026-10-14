import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary disclosure claim.
    final class PrimaryDisclosureClaimView {
        var codeText: String
        var title: String
        var ownerIDText: String
        var bed: String
        var refills: String
        var visible: String
        var channel: String
        var expiresAt: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, title: String, ownerIDText: String, bed: String, refills: String, visible: String, channel: String, expiresAt: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ownerIDText = ownerIDText
            self.bed = bed
            self.refills = refills
            self.visible = visible
            self.channel = channel
            self.expiresAt = expiresAt
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryDisclosureClaimView(_ item: PrimaryDisclosureClaim) -> PrimaryDisclosureClaimView {
        return PrimaryDisclosureClaimView(
            codeText: item.code,
            title: item.title,
            ownerIDText: item.ownerID,
            bed: item.bed,
            refills: String(item.refills),
            visible: "\(item.visible)",
            channel: item.channel,
            expiresAt: String(item.expiresAt),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryDisclosureClaimViews(_ items: [PrimaryDisclosureClaim]) -> [PrimaryDisclosureClaimView] {
        var views: [PrimaryDisclosureClaimView] = []
        for item in items {
            views.append(toPrimaryDisclosureClaimView(item))
        }
        return views
    }

    static func sumPrimaryDisclosureClaimView(_ view: PrimaryDisclosureClaimView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedRefills) + Double(parsedExpiresAt) + Double(parsedSequence)
    }
}
