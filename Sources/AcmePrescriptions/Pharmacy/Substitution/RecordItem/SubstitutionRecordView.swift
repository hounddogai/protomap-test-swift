import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution record.
    final class SubstitutionRecordView {
        var codeText: String
        var name: String
        var acuity: String
        var notesText: String
        var discount: String
        var facility: String
        var attempts: String
        var capacityText: String
        var archivedText: String
        var copay: String
        var encounterIDText: String
        var statusLabel: String

        init(codeText: String, name: String, acuity: String, notesText: String, discount: String, facility: String, attempts: String, capacityText: String, archivedText: String, copay: String, encounterIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuity = acuity
            self.notesText = notesText
            self.discount = discount
            self.facility = facility
            self.attempts = attempts
            self.capacityText = capacityText
            self.archivedText = archivedText
            self.copay = copay
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionRecordView(_ item: SubstitutionRecord) -> SubstitutionRecordView {
        return SubstitutionRecordView(
            codeText: item.code,
            name: item.name,
            acuity: String(item.acuity),
            notesText: item.notes,
            discount: String(format: "%.2f", item.discount),
            facility: item.facility,
            attempts: String(item.attempts),
            capacityText: String(item.capacity),
            archivedText: "\(item.archived)",
            copay: String(format: "%.2f", item.copay),
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionRecordViews(_ items: [SubstitutionRecord]) -> [SubstitutionRecordView] {
        var views: [SubstitutionRecordView] = []
        for item in items {
            views.append(toSubstitutionRecordView(item))
        }
        return views
    }

    static func sumSubstitutionRecordView(_ view: SubstitutionRecordView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAcuity) + parsedDiscount + Double(parsedAttempts)
    }
}
