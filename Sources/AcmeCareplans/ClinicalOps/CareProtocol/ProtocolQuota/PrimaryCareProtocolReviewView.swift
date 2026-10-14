import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary care protocol review.
    final class PrimaryCareProtocolReviewView {
        var codeText: String
        var title: String
        var acuity: String
        var createdAtText: String
        var visitMinutes: String
        var checksum: String
        var versionText: String
        var sequenceText: String
        var revision: String
        var contactEmail: String
        var endsAtText: String
        var statusLabel: String

        init(codeText: String, title: String, acuity: String, createdAtText: String, visitMinutes: String, checksum: String, versionText: String, sequenceText: String, revision: String, contactEmail: String, endsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.acuity = acuity
            self.createdAtText = createdAtText
            self.visitMinutes = visitMinutes
            self.checksum = checksum
            self.versionText = versionText
            self.sequenceText = sequenceText
            self.revision = revision
            self.contactEmail = contactEmail
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCareProtocolReviewView(_ item: PrimaryCareProtocolReview) -> PrimaryCareProtocolReviewView {
        return PrimaryCareProtocolReviewView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            acuity: String(item.acuity),
            createdAtText: String(item.createdAt),
            visitMinutes: String(item.visitMinutes),
            checksum: item.checksum,
            versionText: String(item.version),
            sequenceText: String(item.sequence),
            revision: String(item.revision),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCareProtocolReviewViews(_ items: [PrimaryCareProtocolReview]) -> [PrimaryCareProtocolReviewView] {
        var views: [PrimaryCareProtocolReviewView] = []
        for item in items {
            views.append(toPrimaryCareProtocolReviewView(item))
        }
        return views
    }

    static func sumPrimaryCareProtocolReviewView(_ view: PrimaryCareProtocolReviewView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedAcuity) + Double(parsedCreatedAt) + Double(parsedVisitMinutes)
    }
}
