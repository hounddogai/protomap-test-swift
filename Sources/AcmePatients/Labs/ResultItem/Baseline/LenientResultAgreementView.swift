import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a lenient result agreement.
    final class LenientResultAgreementView {
        var code: String
        var title: String
        var createdAt: String
        var diagnosisCode: String
        var sequenceText: String
        var contactEmail: String
        var notesText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, diagnosisCode: String, sequenceText: String, contactEmail: String, notesText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.diagnosisCode = diagnosisCode
            self.sequenceText = sequenceText
            self.contactEmail = contactEmail
            self.notesText = notesText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toLenientResultAgreementView(_ item: LenientResultAgreement) -> LenientResultAgreementView {
        return LenientResultAgreementView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            diagnosisCode: item.diagnosisCode,
            sequenceText: String(item.sequence),
            contactEmail: item.contactEmail,
            notesText: item.notes,
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientResultAgreementViews(_ items: [LenientResultAgreement]) -> [LenientResultAgreementView] {
        var views: [LenientResultAgreementView] = []
        for item in items {
            views.append(toLenientResultAgreementView(item))
        }
        return views
    }

    static func sumLenientResultAgreementView(_ view: LenientResultAgreementView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedSequence)
    }
}
