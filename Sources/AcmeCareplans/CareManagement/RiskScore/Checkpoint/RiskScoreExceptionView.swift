import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score exception.
    final class RiskScoreExceptionView {
        var code: String
        var title: String
        var facilityText: String
        var versionText: String
        var visitMinutes: String
        var sourceText: String
        var specialty: String
        var acuityText: String
        var checksum: String
        var categoryText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, facilityText: String, versionText: String, visitMinutes: String, sourceText: String, specialty: String, acuityText: String, checksum: String, categoryText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.facilityText = facilityText
            self.versionText = versionText
            self.visitMinutes = visitMinutes
            self.sourceText = sourceText
            self.specialty = specialty
            self.acuityText = acuityText
            self.checksum = checksum
            self.categoryText = categoryText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreExceptionView(_ item: RiskScoreException) -> RiskScoreExceptionView {
        return RiskScoreExceptionView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            facilityText: item.facility,
            versionText: String(item.version),
            visitMinutes: String(item.visitMinutes),
            sourceText: item.source,
            specialty: item.specialty,
            acuityText: String(item.acuity),
            checksum: item.checksum,
            categoryText: item.category,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreExceptionViews(_ items: [RiskScoreException]) -> [RiskScoreExceptionView] {
        var views: [RiskScoreExceptionView] = []
        for item in items {
            views.append(toRiskScoreExceptionView(item))
        }
        return views
    }

    static func sumRiskScoreExceptionView(_ view: RiskScoreExceptionView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedVersion) + Double(parsedVisitMinutes) + Double(parsedAcuity)
    }
}
