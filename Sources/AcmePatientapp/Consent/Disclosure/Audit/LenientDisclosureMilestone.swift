import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient disclosure milestone is in its life cycle.
    enum LenientDisclosureMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient disclosure milestone, with what the planners need to act on it.
    final class LenientDisclosureMilestone {
        var code: String
        var label: String
        var ward: String
        var active: Bool
        var threshold: Double
        var maximum: Double
        var status: LenientDisclosureMilestoneStatus

        init(code: String, label: String, ward: String, active: Bool, threshold: Double, maximum: Double, status: LenientDisclosureMilestoneStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.active = active
            self.threshold = threshold
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientDisclosureMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientDisclosureMilestoneStatus.suspended
            case .pending:
                return next == LenientDisclosureMilestoneStatus.active
            case .active:
                return next == LenientDisclosureMilestoneStatus.suspended
            case .suspended:
                return next == LenientDisclosureMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDisclosureMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient disclosure milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return (threshold * maximum * 100).rounded() / 100
        }

        func copyValue() -> LenientDisclosureMilestone {
            return LenientDisclosureMilestone(
                code: code,
                label: label,
                ward: ward,
                active: active,
                threshold: threshold,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient disclosure milestone in status draft.
    static func newLenientDisclosureMilestone(_ code: String, label: String) -> LenientDisclosureMilestone {
        return LenientDisclosureMilestone(
            code: code,
            label: label,
            ward: "",
            active: false,
            threshold: 0.0,
            maximum: 0.0,
            status: LenientDisclosureMilestoneStatus.draft
        )
    }
}
