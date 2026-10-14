import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary task template.
    final class PrimaryTaskTemplateView {
        var codeText: String
        var name: String
        var ownerID: String
        var checksum: String
        var ward: String
        var diagnosisCode: String
        var priorityText: String
        var procedureCodeText: String
        var statusLabel: String

        init(codeText: String, name: String, ownerID: String, checksum: String, ward: String, diagnosisCode: String, priorityText: String, procedureCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ownerID = ownerID
            self.checksum = checksum
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.priorityText = priorityText
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryTaskTemplateView(_ item: PrimaryTaskTemplate) -> PrimaryTaskTemplateView {
        return PrimaryTaskTemplateView(
            codeText: item.code,
            name: item.name,
            ownerID: item.ownerID,
            checksum: item.checksum,
            ward: item.ward,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            priorityText: String(item.priority),
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryTaskTemplateViews(_ items: [PrimaryTaskTemplate]) -> [PrimaryTaskTemplateView] {
        var views: [PrimaryTaskTemplateView] = []
        for item in items {
            views.append(toPrimaryTaskTemplateView(item))
        }
        return views
    }

    static func sumPrimaryTaskTemplateView(_ view: PrimaryTaskTemplateView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
