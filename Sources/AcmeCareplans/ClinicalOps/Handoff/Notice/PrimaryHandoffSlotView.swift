import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary handoff slot.
    final class PrimaryHandoffSlotView {
        var codeText: String
        var name: String
        var procedureCode: String
        var label: String
        var refillsText: String
        var priority: String
        var specialty: String
        var contactEmailText: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, label: String, refillsText: String, priority: String, specialty: String, contactEmailText: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.label = label
            self.refillsText = refillsText
            self.priority = priority
            self.specialty = specialty
            self.contactEmailText = contactEmailText
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryHandoffSlotView(_ item: PrimaryHandoffSlot) -> PrimaryHandoffSlotView {
        return PrimaryHandoffSlotView(
            codeText: item.code,
            name: item.name,
            procedureCode: item.procedureCode,
            label: item.label,
            refillsText: String(item.refills),
            priority: String(item.priority),
            specialty: item.specialty,
            contactEmailText: item.contactEmail,
            diagnosisCodeText: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryHandoffSlotViews(_ items: [PrimaryHandoffSlot]) -> [PrimaryHandoffSlotView] {
        var views: [PrimaryHandoffSlotView] = []
        for item in items {
            views.append(toPrimaryHandoffSlotView(item))
        }
        return views
    }

    static func sumPrimaryHandoffSlotView(_ view: PrimaryHandoffSlotView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedRefills) + Double(parsedPriority)
    }
}
