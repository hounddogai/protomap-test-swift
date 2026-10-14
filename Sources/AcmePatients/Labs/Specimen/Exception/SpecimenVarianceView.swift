import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen variance.
    final class SpecimenVarianceView {
        var code: String
        var title: String
        var bed: String
        var allergyText: String
        var labelText: String
        var specialty: String
        var patientRefText: String
        var marginText: String
        var statusLabel: String

        init(code: String, title: String, bed: String, allergyText: String, labelText: String, specialty: String, patientRefText: String, marginText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bed = bed
            self.allergyText = allergyText
            self.labelText = labelText
            self.specialty = specialty
            self.patientRefText = patientRefText
            self.marginText = marginText
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenVarianceView(_ item: SpecimenVariance) -> SpecimenVarianceView {
        return SpecimenVarianceView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            bed: Kit.Text.truncate(item.bed, limit: 80),
            allergyText: Kit.Text.truncate(item.allergy, limit: 80),
            labelText: item.label,
            specialty: item.specialty,
            patientRefText: item.patientRef,
            marginText: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenVarianceViews(_ items: [SpecimenVariance]) -> [SpecimenVarianceView] {
        var views: [SpecimenVarianceView] = []
        for item in items {
            views.append(toSpecimenVarianceView(item))
        }
        return views
    }

    static func sumSpecimenVarianceView(_ view: SpecimenVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
