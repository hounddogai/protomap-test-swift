import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority assignment is in its life cycle.
    enum PriorityAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A priority assignment. Its code is unique within a tenant.
    final class PriorityAssignment {
        var code: String
        var label: String
        var active: Bool
        var ward: String
        var channel: String
        var retries: Int
        var acuity: Int
        var status: PriorityAssignmentStatus

        init(code: String, label: String, active: Bool, ward: String, channel: String, retries: Int, acuity: Int, status: PriorityAssignmentStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.ward = ward
            self.channel = channel
            self.retries = retries
            self.acuity = acuity
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

        func canMoveTo(_ next: PriorityAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PriorityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return (Double(retries) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> PriorityAssignment {
            return PriorityAssignment(
                code: code,
                label: label,
                active: active,
                ward: ward,
                channel: channel,
                retries: retries,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a priority assignment in status proposed.
    static func newPriorityAssignment(_ code: String, label: String) -> PriorityAssignment {
        return PriorityAssignment(
            code: code,
            label: label,
            active: false,
            ward: "",
            channel: "",
            retries: 0,
            acuity: 0,
            status: PriorityAssignmentStatus.proposed
        )
    }
}
