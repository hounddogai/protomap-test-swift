import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary skill mix score.
    final class PrimarySkillMixScoreView {
        var code: String
        var name: String
        var copay: String
        var facility: String
        var createdAt: String
        var contactEmail: String
        var procedureCode: String
        var archived: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, copay: String, facility: String, createdAt: String, contactEmail: String, procedureCode: String, archived: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.copay = copay
            self.facility = facility
            self.createdAt = createdAt
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.archived = archived
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySkillMixScoreView(_ item: PrimarySkillMixScore) -> PrimarySkillMixScoreView {
        return PrimarySkillMixScoreView(
            code: item.code,
            name: item.name,
            copay: String(format: "%.2f", item.copay),
            facility: item.facility,
            createdAt: String(item.createdAt),
            contactEmail: item.contactEmail,
            procedureCode: item.procedureCode,
            archived: "\(item.archived)",
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySkillMixScoreViews(_ items: [PrimarySkillMixScore]) -> [PrimarySkillMixScoreView] {
        var views: [PrimarySkillMixScoreView] = []
        for item in items {
            views.append(toPrimarySkillMixScoreView(item))
        }
        return views
    }

    static func sumPrimarySkillMixScoreView(_ view: PrimarySkillMixScoreView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCopay + Double(parsedCreatedAt) + parsedCeiling
    }
}
