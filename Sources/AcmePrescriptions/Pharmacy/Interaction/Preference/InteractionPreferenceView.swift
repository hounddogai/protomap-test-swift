import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction preference.
    final class InteractionPreferenceView {
        var code: String
        var label: String
        var discountText: String
        var diagnosisCode: String
        var region: String
        var allergy: String
        var checksum: String
        var specialty: String
        var procedureCode: String
        var version: String
        var statusLabel: String

        init(code: String, label: String, discountText: String, diagnosisCode: String, region: String, allergy: String, checksum: String, specialty: String, procedureCode: String, version: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discountText = discountText
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.allergy = allergy
            self.checksum = checksum
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionPreferenceView(_ item: InteractionPreference) -> InteractionPreferenceView {
        return InteractionPreferenceView(
            code: item.code,
            label: item.label,
            discountText: String(format: "%.2f", item.discount),
            diagnosisCode: item.diagnosisCode,
            region: Kit.Text.truncate(item.region, limit: 80),
            allergy: item.allergy,
            checksum: item.checksum,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionPreferenceViews(_ items: [InteractionPreference]) -> [InteractionPreferenceView] {
        var views: [InteractionPreferenceView] = []
        for item in items {
            views.append(toInteractionPreferenceView(item))
        }
        return views
    }

    static func sumInteractionPreferenceView(_ view: InteractionPreferenceView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedDiscount + Double(parsedVersion)
    }
}
