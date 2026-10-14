import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program reservation is in its life cycle.
    enum ProgramReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A program reservation. Its code is unique within a tenant.
    final class ProgramReservation {
        var code: String
        var name: String
        var segment: String
        var procedureCode: String
        var ceiling: Double
        var contactEmail: String
        var status: ProgramReservationStatus

        init(code: String, name: String, segment: String, procedureCode: String, ceiling: Double, contactEmail: String, status: ProgramReservationStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.procedureCode = procedureCode
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramReservationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProgramReservationStatus.reopened || next == ProgramReservationStatus.archived
            case .inReview:
                return next == ProgramReservationStatus.resolved
            case .resolved:
                return next == ProgramReservationStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ProgramReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> ProgramReservation {
            return ProgramReservation(
                code: code,
                name: name,
                segment: segment,
                procedureCode: procedureCode,
                ceiling: ceiling,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a program reservation in status open.
    static func newProgramReservation(_ code: String, name: String) -> ProgramReservation {
        return ProgramReservation(
            code: code,
            name: name,
            segment: "",
            procedureCode: "",
            ceiling: 0.0,
            contactEmail: "",
            status: ProgramReservationStatus.`open`
        )
    }
}
