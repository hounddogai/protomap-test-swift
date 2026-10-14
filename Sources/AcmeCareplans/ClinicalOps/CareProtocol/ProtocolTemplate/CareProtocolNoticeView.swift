import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol notice.
    final class CareProtocolNoticeView {
        var code: String
        var title: String
        var minimumText: String
        var revision: String
        var approvedText: String
        var sequence: String
        var description: String
        var dosageMg: String
        var clinicianID: String
        var startsAt: String
        var statusLabel: String

        init(code: String, title: String, minimumText: String, revision: String, approvedText: String, sequence: String, description: String, dosageMg: String, clinicianID: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimumText = minimumText
            self.revision = revision
            self.approvedText = approvedText
            self.sequence = sequence
            self.description = description
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolNoticeView(_ item: CareProtocolNotice) -> CareProtocolNoticeView {
        return CareProtocolNoticeView(
            code: item.code,
            title: item.title,
            minimumText: String(format: "%.2f", item.minimum),
            revision: String(item.revision),
            approvedText: "\(item.approved)",
            sequence: String(item.sequence),
            description: item.description,
            dosageMg: String(format: "%.2f", item.dosageMg),
            clinicianID: item.clinicianID,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolNoticeViews(_ items: [CareProtocolNotice]) -> [CareProtocolNoticeView] {
        var views: [CareProtocolNoticeView] = []
        for item in items {
            views.append(toCareProtocolNoticeView(item))
        }
        return views
    }

    static func sumCareProtocolNoticeView(_ view: CareProtocolNoticeView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedMinimum + Double(parsedRevision) + Double(parsedSequence)
    }
}
