import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program group.
    final class ProgramGroupView {
        var code: String
        var label: String
        var encounterID: String
        var reviewer: String
        var specialty: String
        var copay: String
        var contactEmail: String
        var margin: String
        var clinicianIDText: String
        var ownerID: String
        var notes: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, reviewer: String, specialty: String, copay: String, contactEmail: String, margin: String, clinicianIDText: String, ownerID: String, notes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.reviewer = reviewer
            self.specialty = specialty
            self.copay = copay
            self.contactEmail = contactEmail
            self.margin = margin
            self.clinicianIDText = clinicianIDText
            self.ownerID = ownerID
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toProgramGroupView(_ item: ProgramGroup) -> ProgramGroupView {
        return ProgramGroupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 80),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 40),
            reviewer: item.reviewer,
            specialty: item.specialty,
            copay: String(format: "%.2f", item.copay),
            contactEmail: item.contactEmail,
            margin: String(format: "%.2f", item.margin),
            clinicianIDText: item.clinicianID,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramGroupViews(_ items: [ProgramGroup]) -> [ProgramGroupView] {
        var views: [ProgramGroupView] = []
        for item in items {
            views.append(toProgramGroupView(item))
        }
        return views
    }

    static func sumProgramGroupView(_ view: ProgramGroupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedCopay + parsedMargin
    }
}
