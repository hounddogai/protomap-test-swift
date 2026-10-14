import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient goal proposal is in its life cycle.
    enum LenientGoalProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient goal proposal as the goal team keeps it.
    final class LenientGoalProposal {
        var code: String
        var label: String
        var timezone: String
        var unit: String
        var threshold: Double
        var createdAt: Int
        var visitMinutes: Int
        var status: LenientGoalProposalStatus

        init(code: String, label: String, timezone: String, unit: String, threshold: Double, createdAt: Int, visitMinutes: Int, status: LenientGoalProposalStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.unit = unit
            self.threshold = threshold
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: LenientGoalProposalStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientGoalProposalStatus.completed
            case .scheduled:
                return next == LenientGoalProposalStatus.inProgress || next == LenientGoalProposalStatus.completed
            case .inProgress:
                return next == LenientGoalProposalStatus.cancelled
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

        func moveTo(_ next: LenientGoalProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient goal proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return (Double(createdAt) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LenientGoalProposal {
            return LenientGoalProposal(
                code: code,
                label: label,
                timezone: timezone,
                unit: unit,
                threshold: threshold,
                createdAt: createdAt,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient goal proposal in status planned.
    static func newLenientGoalProposal(_ code: String, label: String) -> LenientGoalProposal {
        return LenientGoalProposal(
            code: code,
            label: label,
            timezone: "",
            unit: "",
            threshold: 0.0,
            createdAt: 0,
            visitMinutes: 0,
            status: LenientGoalProposalStatus.planned
        )
    }
}
