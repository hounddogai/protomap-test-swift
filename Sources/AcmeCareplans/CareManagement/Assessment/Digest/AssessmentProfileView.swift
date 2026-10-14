import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment profile.
    final class AssessmentProfileView {
        var code: String
        var nameText: String
        var createdAt: String
        var visible: String
        var channel: String
        var procedureCode: String
        var segment: String
        var phone: String
        var diagnosisCodeText: String
        var archived: String
        var statusLabel: String

        init(code: String, nameText: String, createdAt: String, visible: String, channel: String, procedureCode: String, segment: String, phone: String, diagnosisCodeText: String, archived: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.createdAt = createdAt
            self.visible = visible
            self.channel = channel
            self.procedureCode = procedureCode
            self.segment = segment
            self.phone = phone
            self.diagnosisCodeText = diagnosisCodeText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentProfileView(_ item: AssessmentProfile) -> AssessmentProfileView {
        return AssessmentProfileView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            createdAt: String(item.createdAt),
            visible: "\(item.visible)",
            channel: item.channel,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            segment: item.segment,
            phone: item.phone,
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentProfileViews(_ items: [AssessmentProfile]) -> [AssessmentProfileView] {
        var views: [AssessmentProfileView] = []
        for item in items {
            views.append(toAssessmentProfileView(item))
        }
        return views
    }

    static func sumAssessmentProfileView(_ view: AssessmentProfileView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
