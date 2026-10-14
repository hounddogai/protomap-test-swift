import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen score.
    final class SpecimenScoreView {
        var codeText: String
        var nameText: String
        var segment: String
        var externalRef: String
        var expiresAt: String
        var windowDaysText: String
        var locale: String
        var patientRef: String
        var clinicianIDText: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, nameText: String, segment: String, externalRef: String, expiresAt: String, windowDaysText: String, locale: String, patientRef: String, clinicianIDText: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.segment = segment
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.windowDaysText = windowDaysText
            self.locale = locale
            self.patientRef = patientRef
            self.clinicianIDText = clinicianIDText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenScoreView(_ item: SpecimenScore) -> SpecimenScoreView {
        return SpecimenScoreView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            segment: item.segment,
            externalRef: item.externalRef,
            expiresAt: String(item.expiresAt),
            windowDaysText: String(item.windowDays),
            locale: item.locale,
            patientRef: item.patientRef,
            clinicianIDText: item.clinicianID,
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenScoreViews(_ items: [SpecimenScore]) -> [SpecimenScoreView] {
        var views: [SpecimenScoreView] = []
        for item in items {
            views.append(toSpecimenScoreView(item))
        }
        return views
    }

    static func sumSpecimenScoreView(_ view: SpecimenScoreView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedWindowDays)
    }
}
