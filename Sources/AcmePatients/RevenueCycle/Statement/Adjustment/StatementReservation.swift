import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement reservation is in its life cycle.
    enum StatementReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One statement reservation, with what the planners need to act on it.
    final class StatementReservation {
        var code: String
        var title: String
        var ward: String
        var clinicianID: String
        var pinned: Bool
        var graceDays: Int
        var archived: Bool
        var checksum: String
        var status: StatementReservationStatus

        init(code: String, title: String, ward: String, clinicianID: String, pinned: Bool, graceDays: Int, archived: Bool, checksum: String, status: StatementReservationStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.graceDays = graceDays
            self.archived = archived
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StatementReservationStatus.withdrawn
            case .approved:
                return next == StatementReservationStatus.rejected || next == StatementReservationStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> StatementReservation {
            return StatementReservation(
                code: code,
                title: title,
                ward: ward,
                clinicianID: clinicianID,
                pinned: pinned,
                graceDays: graceDays,
                archived: archived,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a statement reservation in status proposed.
    static func newStatementReservation(_ code: String, title: String) -> StatementReservation {
        return StatementReservation(
            code: code,
            title: title,
            ward: "",
            clinicianID: "",
            pinned: false,
            graceDays: 0,
            archived: false,
            checksum: "",
            status: StatementReservationStatus.proposed
        )
    }
}
