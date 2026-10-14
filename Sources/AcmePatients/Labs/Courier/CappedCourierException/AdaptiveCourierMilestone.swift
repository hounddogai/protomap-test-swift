import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive courier milestone is in its life cycle.
    enum AdaptiveCourierMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive courier milestone, with what the planners need to act on it.
    final class AdaptiveCourierMilestone {
        var code: String
        var label: String
        var budget: Double
        var visible: Bool
        var checksum: String
        var status: AdaptiveCourierMilestoneStatus

        init(code: String, label: String, budget: Double, visible: Bool, checksum: String, status: AdaptiveCourierMilestoneStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.visible = visible
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

        func canMoveTo(_ next: AdaptiveCourierMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveCourierMilestoneStatus.rejected
            case .rejected:
                return next == AdaptiveCourierMilestoneStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCourierMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive courier milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> AdaptiveCourierMilestone {
            return AdaptiveCourierMilestone(
                code: code,
                label: label,
                budget: budget,
                visible: visible,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive courier milestone in status proposed.
    static func newAdaptiveCourierMilestone(_ code: String, label: String) -> AdaptiveCourierMilestone {
        return AdaptiveCourierMilestone(
            code: code,
            label: label,
            budget: 0.0,
            visible: false,
            checksum: "",
            status: AdaptiveCourierMilestoneStatus.proposed
        )
    }
}
