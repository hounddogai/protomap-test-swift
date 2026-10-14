import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation snapshot.
    final class RevocationSnapshotView {
        var codeText: String
        var titleText: String
        var pinned: String
        var payerText: String
        var quantityText: String
        var patientRef: String
        var approved: String
        var acuityText: String
        var checksum: String
        var nameText: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, titleText: String, pinned: String, payerText: String, quantityText: String, patientRef: String, approved: String, acuityText: String, checksum: String, nameText: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.pinned = pinned
            self.payerText = payerText
            self.quantityText = quantityText
            self.patientRef = patientRef
            self.approved = approved
            self.acuityText = acuityText
            self.checksum = checksum
            self.nameText = nameText
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationSnapshotView(_ item: RevocationSnapshot) -> RevocationSnapshotView {
        return RevocationSnapshotView(
            codeText: item.code,
            titleText: item.title,
            pinned: "\(item.pinned)",
            payerText: item.payer,
            quantityText: String(item.quantity),
            patientRef: item.patientRef,
            approved: "\(item.approved)",
            acuityText: String(item.acuity),
            checksum: item.checksum,
            nameText: item.name,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationSnapshotViews(_ items: [RevocationSnapshot]) -> [RevocationSnapshotView] {
        var views: [RevocationSnapshotView] = []
        for item in items {
            views.append(toRevocationSnapshotView(item))
        }
        return views
    }

    static func sumRevocationSnapshotView(_ view: RevocationSnapshotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedQuantity) + Double(parsedAcuity) + Double(parsedVisitMinutes)
    }
}
