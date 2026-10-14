import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a lenient acuity plan policy.
    final class LenientAcuityPlanPolicyView {
        var code: String
        var label: String
        var capacityText: String
        var createdAtText: String
        var visible: String
        var acuityText: String
        var specialty: String
        var dosageMg: String
        var summary: String
        var updatedAt: String
        var notesText: String
        var statusLabel: String

        init(code: String, label: String, capacityText: String, createdAtText: String, visible: String, acuityText: String, specialty: String, dosageMg: String, summary: String, updatedAt: String, notesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacityText = capacityText
            self.createdAtText = createdAtText
            self.visible = visible
            self.acuityText = acuityText
            self.specialty = specialty
            self.dosageMg = dosageMg
            self.summary = summary
            self.updatedAt = updatedAt
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAcuityPlanPolicyView(_ item: LenientAcuityPlanPolicy) -> LenientAcuityPlanPolicyView {
        return LenientAcuityPlanPolicyView(
            code: item.code,
            label: item.label,
            capacityText: String(item.capacity),
            createdAtText: String(item.createdAt),
            visible: "\(item.visible)",
            acuityText: String(item.acuity),
            specialty: item.specialty,
            dosageMg: String(format: "%.2f", item.dosageMg),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            updatedAt: String(item.updatedAt),
            notesText: Kit.Text.truncate(item.notes, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAcuityPlanPolicyViews(_ items: [LenientAcuityPlanPolicy]) -> [LenientAcuityPlanPolicyView] {
        var views: [LenientAcuityPlanPolicyView] = []
        for item in items {
            views.append(toLenientAcuityPlanPolicyView(item))
        }
        return views
    }

    static func sumLenientAcuityPlanPolicyView(_ view: LenientAcuityPlanPolicyView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCapacity) + Double(parsedCreatedAt) + Double(parsedAcuity)
    }
}
