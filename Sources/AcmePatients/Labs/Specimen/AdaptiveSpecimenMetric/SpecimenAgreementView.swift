import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen agreement.
    final class SpecimenAgreementView {
        var codeText: String
        var label: String
        var maximum: String
        var specialty: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, label: String, maximum: String, specialty: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.maximum = maximum
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenAgreementView(_ item: SpecimenAgreement) -> SpecimenAgreementView {
        return SpecimenAgreementView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            specialty: Kit.Text.truncate(item.specialty, limit: 80),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenAgreementViews(_ items: [SpecimenAgreement]) -> [SpecimenAgreementView] {
        var views: [SpecimenAgreementView] = []
        for item in items {
            views.append(toSpecimenAgreementView(item))
        }
        return views
    }

    static func sumSpecimenAgreementView(_ view: SpecimenAgreementView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
