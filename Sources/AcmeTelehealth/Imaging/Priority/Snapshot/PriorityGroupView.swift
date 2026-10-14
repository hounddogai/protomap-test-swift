import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority group.
    final class PriorityGroupView {
        var codeText: String
        var labelText: String
        var allergy: String
        var archived: String
        var diagnosisCodeText: String
        var createdAt: String
        var retries: String
        var refillsText: String
        var acuity: String
        var discount: String
        var visible: String
        var statusLabel: String

        init(codeText: String, labelText: String, allergy: String, archived: String, diagnosisCodeText: String, createdAt: String, retries: String, refillsText: String, acuity: String, discount: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.allergy = allergy
            self.archived = archived
            self.diagnosisCodeText = diagnosisCodeText
            self.createdAt = createdAt
            self.retries = retries
            self.refillsText = refillsText
            self.acuity = acuity
            self.discount = discount
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityGroupView(_ item: PriorityGroup) -> PriorityGroupView {
        return PriorityGroupView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            allergy: item.allergy,
            archived: "\(item.archived)",
            diagnosisCodeText: item.diagnosisCode,
            createdAt: String(item.createdAt),
            retries: String(item.retries),
            refillsText: String(item.refills),
            acuity: String(item.acuity),
            discount: String(format: "%.2f", item.discount),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityGroupViews(_ items: [PriorityGroup]) -> [PriorityGroupView] {
        var views: [PriorityGroupView] = []
        for item in items {
            views.append(toPriorityGroupView(item))
        }
        return views
    }

    static func sumPriorityGroupView(_ view: PriorityGroupView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRetries) + Double(parsedRefills)
    }
}
