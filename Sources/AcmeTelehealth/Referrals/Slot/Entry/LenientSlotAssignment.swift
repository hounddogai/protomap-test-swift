import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient slot assignment is in its life cycle.
    enum LenientSlotAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient slot assignment. Its code is unique within a tenant.
    final class LenientSlotAssignment {
        var code: String
        var name: String
        var attempts: Int
        var specialty: String
        var visible: Bool
        var contactEmail: String
        var label: String
        var status: LenientSlotAssignmentStatus

        init(code: String, name: String, attempts: Int, specialty: String, visible: Bool, contactEmail: String, label: String, status: LenientSlotAssignmentStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.specialty = specialty
            self.visible = visible
            self.contactEmail = contactEmail
            self.label = label
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

        func canMoveTo(_ next: LenientSlotAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == LenientSlotAssignmentStatus.published || next == LenientSlotAssignmentStatus.retired
            case .validated:
                return next == LenientSlotAssignmentStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LenientSlotAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient slot assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> LenientSlotAssignment {
            return LenientSlotAssignment(
                code: code,
                name: name,
                attempts: attempts,
                specialty: specialty,
                visible: visible,
                contactEmail: contactEmail,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient slot assignment in status created.
    static func newLenientSlotAssignment(_ code: String, name: String) -> LenientSlotAssignment {
        return LenientSlotAssignment(
            code: code,
            name: name,
            attempts: 0,
            specialty: "",
            visible: false,
            contactEmail: "",
            label: "",
            status: LenientSlotAssignmentStatus.created
        )
    }
}
