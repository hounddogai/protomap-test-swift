import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a program reservation.
    final class ProgramReservationView {
        var code: String
        var name: String
        var segmentText: String
        var procedureCode: String
        var ceilingText: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, name: String, segmentText: String, procedureCode: String, ceilingText: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segmentText = segmentText
            self.procedureCode = procedureCode
            self.ceilingText = ceilingText
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toProgramReservationView(_ item: ProgramReservation) -> ProgramReservationView {
        return ProgramReservationView(
            code: item.code,
            name: item.name,
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            ceilingText: String(format: "%.2f", item.ceiling),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProgramReservationViews(_ items: [ProgramReservation]) -> [ProgramReservationView] {
        var views: [ProgramReservationView] = []
        for item in items {
            views.append(toProgramReservationView(item))
        }
        return views
    }

    static func sumProgramReservationView(_ view: ProgramReservationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
