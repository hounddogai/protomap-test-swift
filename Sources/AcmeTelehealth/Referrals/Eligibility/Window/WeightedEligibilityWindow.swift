import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted eligibility window is in its life cycle.
    enum WeightedEligibilityWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted eligibility window, with what the planners need to act on it.
    final class WeightedEligibilityWindow {
        var code: String
        var label: String
        var revision: Int
        var bed: String
        var pinned: Bool
        var status: WeightedEligibilityWindowStatus

        init(code: String, label: String, revision: Int, bed: String, pinned: Bool, status: WeightedEligibilityWindowStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.bed = bed
            self.pinned = pinned
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

        func canMoveTo(_ next: WeightedEligibilityWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedEligibilityWindowStatus.approved || next == WeightedEligibilityWindowStatus.withdrawn
            case .approved:
                return next == WeightedEligibilityWindowStatus.withdrawn
            case .rejected:
                return next == WeightedEligibilityWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedEligibilityWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted eligibility window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> WeightedEligibilityWindow {
            return WeightedEligibilityWindow(
                code: code,
                label: label,
                revision: revision,
                bed: bed,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted eligibility window in status proposed.
    static func newWeightedEligibilityWindow(_ code: String, label: String) -> WeightedEligibilityWindow {
        return WeightedEligibilityWindow(
            code: code,
            label: label,
            revision: 0,
            bed: "",
            pinned: false,
            status: WeightedEligibilityWindowStatus.proposed
        )
    }
}
