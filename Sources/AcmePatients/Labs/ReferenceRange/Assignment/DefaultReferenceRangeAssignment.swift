import AcmePlatform
import Foundation

extension Labs {
    /// Where a default reference range assignment is in its life cycle.
    enum DefaultReferenceRangeAssignmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default reference range assignment as the reference range team keeps it.
    final class DefaultReferenceRangeAssignment {
        var code: String
        var name: String
        var attempts: Int
        var quantity: Int
        var sequence: Int
        var priority: Int
        var allergy: String
        var specialty: String
        var status: DefaultReferenceRangeAssignmentStatus

        init(code: String, name: String, attempts: Int, quantity: Int, sequence: Int, priority: Int, allergy: String, specialty: String, status: DefaultReferenceRangeAssignmentStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.quantity = quantity
            self.sequence = sequence
            self.priority = priority
            self.allergy = allergy
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultReferenceRangeAssignmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultReferenceRangeAssignmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReferenceRangeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default reference range assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((Double(priority) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReferenceRangeAssignment {
            return DefaultReferenceRangeAssignment(
                code: code,
                name: name,
                attempts: attempts,
                quantity: quantity,
                sequence: sequence,
                priority: priority,
                allergy: allergy,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default reference range assignment in status requested.
    static func newDefaultReferenceRangeAssignment(_ code: String, name: String) -> DefaultReferenceRangeAssignment {
        return DefaultReferenceRangeAssignment(
            code: code,
            name: name,
            attempts: 0,
            quantity: 0,
            sequence: 0,
            priority: 0,
            allergy: "",
            specialty: "",
            status: DefaultReferenceRangeAssignmentStatus.requested
        )
    }
}
