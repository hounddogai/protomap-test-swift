import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted follow up assignment is in its life cycle.
    enum WeightedFollowUpAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted follow up assignment. Its code is unique within a tenant.
    final class WeightedFollowUpAssignment {
        var code: String
        var label: String
        var visible: Bool
        var attempts: Int
        var checksum: String
        var source: String
        var copay: Double
        var minimum: Double
        var status: WeightedFollowUpAssignmentStatus

        init(code: String, label: String, visible: Bool, attempts: Int, checksum: String, source: String, copay: Double, minimum: Double, status: WeightedFollowUpAssignmentStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.attempts = attempts
            self.checksum = checksum
            self.source = source
            self.copay = copay
            self.minimum = minimum
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

        func canMoveTo(_ next: WeightedFollowUpAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedFollowUpAssignmentStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedFollowUpAssignmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedFollowUpAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted follow up assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(attempts) + copay) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFollowUpAssignment {
            return WeightedFollowUpAssignment(
                code: code,
                label: label,
                visible: visible,
                attempts: attempts,
                checksum: checksum,
                source: source,
                copay: copay,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted follow up assignment in status proposed.
    static func newWeightedFollowUpAssignment(_ code: String, label: String) -> WeightedFollowUpAssignment {
        return WeightedFollowUpAssignment(
            code: code,
            label: label,
            visible: false,
            attempts: 0,
            checksum: "",
            source: "",
            copay: 0.0,
            minimum: 0.0,
            status: WeightedFollowUpAssignmentStatus.proposed
        )
    }
}
