import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program record.
    final class ProgramRecordView {
        var code: String
        var labelText: String
        var revision: String
        var contactEmail: String
        var source: String
        var amountText: String
        var statusLabel: String

        init(code: String, labelText: String, revision: String, contactEmail: String, source: String, amountText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.revision = revision
            self.contactEmail = contactEmail
            self.source = source
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramRecordView(_ item: ProgramRecord) -> ProgramRecordView {
        return ProgramRecordView(
            code: item.code,
            labelText: item.label,
            revision: String(item.revision),
            contactEmail: item.contactEmail,
            source: item.source,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramRecordViews(_ items: [ProgramRecord]) -> [ProgramRecordView] {
        var views: [ProgramRecordView] = []
        for item in items {
            views.append(toProgramRecordView(item))
        }
        return views
    }

    static func sumProgramRecordView(_ view: ProgramRecordView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedRevision) + parsedAmount
    }
}
