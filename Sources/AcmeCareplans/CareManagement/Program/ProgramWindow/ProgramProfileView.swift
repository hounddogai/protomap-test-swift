import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program profile.
    final class ProgramProfileView {
        var code: String
        var label: String
        var procedureCodeText: String
        var externalRef: String
        var revision: String
        var quantity: String
        var description: String
        var weightText: String
        var contactEmailText: String
        var ratio: String
        var statusLabel: String

        init(code: String, label: String, procedureCodeText: String, externalRef: String, revision: String, quantity: String, description: String, weightText: String, contactEmailText: String, ratio: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCodeText = procedureCodeText
            self.externalRef = externalRef
            self.revision = revision
            self.quantity = quantity
            self.description = description
            self.weightText = weightText
            self.contactEmailText = contactEmailText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toProgramProfileView(_ item: ProgramProfile) -> ProgramProfileView {
        return ProgramProfileView(
            code: item.code,
            label: item.label,
            procedureCodeText: item.procedureCode,
            externalRef: item.externalRef,
            revision: String(item.revision),
            quantity: String(item.quantity),
            description: Kit.Text.truncate(item.description, limit: 64),
            weightText: String(format: "%.2f", item.weight),
            contactEmailText: item.contactEmail,
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramProfileViews(_ items: [ProgramProfile]) -> [ProgramProfileView] {
        var views: [ProgramProfileView] = []
        for item in items {
            views.append(toProgramProfileView(item))
        }
        return views
    }

    static func sumProgramProfileView(_ view: ProgramProfileView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRevision) + Double(parsedQuantity) + parsedWeight
    }
}
