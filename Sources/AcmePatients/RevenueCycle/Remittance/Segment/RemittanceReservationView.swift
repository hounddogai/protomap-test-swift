import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance reservation.
    final class RemittanceReservationView {
        var codeText: String
        var labelText: String
        var patientRef: String
        var ceiling: String
        var capacity: String
        var clinicianIDText: String
        var revision: String
        var active: String
        var limit: String
        var phoneText: String
        var statusLabel: String

        init(codeText: String, labelText: String, patientRef: String, ceiling: String, capacity: String, clinicianIDText: String, revision: String, active: String, limit: String, phoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.patientRef = patientRef
            self.ceiling = ceiling
            self.capacity = capacity
            self.clinicianIDText = clinicianIDText
            self.revision = revision
            self.active = active
            self.limit = limit
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceReservationView(_ item: RemittanceReservation) -> RemittanceReservationView {
        return RemittanceReservationView(
            codeText: item.code,
            labelText: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            capacity: String(item.capacity),
            clinicianIDText: item.clinicianID,
            revision: String(item.revision),
            active: "\(item.active)",
            limit: String(item.limit),
            phoneText: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceReservationViews(_ items: [RemittanceReservation]) -> [RemittanceReservationView] {
        var views: [RemittanceReservationView] = []
        for item in items {
            views.append(toRemittanceReservationView(item))
        }
        return views
    }

    static func sumRemittanceReservationView(_ view: RemittanceReservationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCeiling + Double(parsedCapacity) + Double(parsedRevision)
    }
}
