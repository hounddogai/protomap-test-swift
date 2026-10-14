import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance reservation is in its life cycle.
    enum RemittanceReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A remittance reservation. Its code is unique within a tenant.
    final class RemittanceReservation {
        var code: String
        var label: String
        var patientRef: String
        var ceiling: Double
        var capacity: Int
        var clinicianID: String
        var revision: Int
        var active: Bool
        var limit: Int
        var phone: String
        var status: RemittanceReservationStatus

        init(code: String, label: String, patientRef: String, ceiling: Double, capacity: Int, clinicianID: String, revision: Int, active: Bool, limit: Int, phone: String, status: RemittanceReservationStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.ceiling = ceiling
            self.capacity = capacity
            self.clinicianID = clinicianID
            self.revision = revision
            self.active = active
            self.limit = limit
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceReservationStatus) -> Bool {
            switch status {
            case .created:
                return next == RemittanceReservationStatus.validated || next == RemittanceReservationStatus.retired
            case .validated:
                return next == RemittanceReservationStatus.retired
            case .published:
                return next == RemittanceReservationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("remittance reservation") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(capacity) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceReservation {
            return RemittanceReservation(
                code: code,
                label: label,
                patientRef: patientRef,
                ceiling: ceiling,
                capacity: capacity,
                clinicianID: clinicianID,
                revision: revision,
                active: active,
                limit: limit,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a remittance reservation in status created.
    static func newRemittanceReservation(_ code: String, label: String) -> RemittanceReservation {
        return RemittanceReservation(
            code: code,
            label: label,
            patientRef: "",
            ceiling: 0.0,
            capacity: 0,
            clinicianID: "",
            revision: 0,
            active: false,
            limit: 0,
            phone: "",
            status: RemittanceReservationStatus.created
        )
    }
}
