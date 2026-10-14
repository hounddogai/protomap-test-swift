import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted formulary agreement.
    final class WeightedFormularyAgreementView {
        var code: String
        var label: String
        var refills: String
        var durationMinutes: String
        var priority: String
        var specialtyText: String
        var encounterID: String
        var statusLabel: String

        init(code: String, label: String, refills: String, durationMinutes: String, priority: String, specialtyText: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.refills = refills
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.specialtyText = specialtyText
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFormularyAgreementView(_ item: WeightedFormularyAgreement) -> WeightedFormularyAgreementView {
        return WeightedFormularyAgreementView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            refills: String(item.refills),
            durationMinutes: String(item.durationMinutes),
            priority: String(item.priority),
            specialtyText: item.specialty,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFormularyAgreementViews(_ items: [WeightedFormularyAgreement]) -> [WeightedFormularyAgreementView] {
        var views: [WeightedFormularyAgreementView] = []
        for item in items {
            views.append(toWeightedFormularyAgreementView(item))
        }
        return views
    }

    static func sumWeightedFormularyAgreementView(_ view: WeightedFormularyAgreementView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedRefills) + Double(parsedDurationMinutes) + Double(parsedPriority)
    }
}
