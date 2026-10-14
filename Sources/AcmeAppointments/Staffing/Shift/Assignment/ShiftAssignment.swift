import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift assignment is in its life cycle.
    enum ShiftAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A shift assignment. Its code is unique within a tenant.
    final class ShiftAssignment {
        var code: String
        var title: String
        var facility: String
        var visible: Bool
        var retries: Int
        var patientRef: String
        var ownerID: String
        var amount: Double
        var weight: Double
        var procedureCode: String
        var tags: [String]
        var status: ShiftAssignmentStatus

        init(code: String, title: String, facility: String, visible: Bool, retries: Int, patientRef: String, ownerID: String, amount: Double, weight: Double, procedureCode: String, tags: [String], status: ShiftAssignmentStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.visible = visible
            self.retries = retries
            self.patientRef = patientRef
            self.ownerID = ownerID
            self.amount = amount
            self.weight = weight
            self.procedureCode = procedureCode
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == ShiftAssignmentStatus.warming || next == ShiftAssignmentStatus.ready
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ShiftAssignmentStatus.draining || next == ShiftAssignmentStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ShiftAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("shift assignment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return ((weight - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftAssignment {
            return ShiftAssignment(
                code: code,
                title: title,
                facility: facility,
                visible: visible,
                retries: retries,
                patientRef: patientRef,
                ownerID: ownerID,
                amount: amount,
                weight: weight,
                procedureCode: procedureCode,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a shift assignment in status idle.
    static func newShiftAssignment(_ code: String, title: String) -> ShiftAssignment {
        return ShiftAssignment(
            code: code,
            title: title,
            facility: "",
            visible: false,
            retries: 0,
            patientRef: "",
            ownerID: "",
            amount: 0.0,
            weight: 0.0,
            procedureCode: "",
            tags: [],
            status: ShiftAssignmentStatus.idle
        )
    }
}
