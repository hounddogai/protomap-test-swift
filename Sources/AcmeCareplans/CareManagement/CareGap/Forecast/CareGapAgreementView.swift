import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap agreement.
    final class CareGapAgreementView {
        var code: String
        var title: String
        var specialty: String
        var createdAt: String
        var acuity: String
        var archived: String
        var visible: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, title: String, specialty: String, createdAt: String, acuity: String, archived: String, visible: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.createdAt = createdAt
            self.acuity = acuity
            self.archived = archived
            self.visible = visible
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapAgreementView(_ item: CareGapAgreement) -> CareGapAgreementView {
        return CareGapAgreementView(
            code: item.code,
            title: item.title,
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            createdAt: String(item.createdAt),
            acuity: String(item.acuity),
            archived: "\(item.archived)",
            visible: "\(item.visible)",
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapAgreementViews(_ items: [CareGapAgreement]) -> [CareGapAgreementView] {
        var views: [CareGapAgreementView] = []
        for item in items {
            views.append(toCareGapAgreementView(item))
        }
        return views
    }

    static func sumCareGapAgreementView(_ view: CareGapAgreementView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedAcuity) + parsedCeiling
    }
}
