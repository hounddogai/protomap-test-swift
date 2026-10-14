import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial assignment is in its life cycle.
    enum DenialAssignmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A denial assignment. Its code is unique within a tenant.
    final class DenialAssignment {
        var code: String
        var label: String
        var phone: String
        var contactEmail: String
        var ratio: Double
        var name: String
        var status: DenialAssignmentStatus

        init(code: String, label: String, phone: String, contactEmail: String, ratio: Double, name: String, status: DenialAssignmentStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DenialAssignmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DenialAssignmentStatus.completed || next == DenialAssignmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DenialAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> DenialAssignment {
            return DenialAssignment(
                code: code,
                label: label,
                phone: phone,
                contactEmail: contactEmail,
                ratio: ratio,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a denial assignment in status planned.
    static func newDenialAssignment(_ code: String, label: String) -> DenialAssignment {
        return DenialAssignment(
            code: code,
            label: label,
            phone: "",
            contactEmail: "",
            ratio: 0.0,
            name: "",
            status: DenialAssignmentStatus.planned
        )
    }
}
