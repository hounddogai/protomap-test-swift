import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending charge proposal is in its life cycle.
    enum PendingChargeProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending charge proposal and its current status.
    final class PendingChargeProposal {
        var code: String
        var title: String
        var maximum: Double
        var budget: Double
        var ratio: Double
        var acuity: Int
        var channel: String
        var amount: Double
        var approved: Bool
        var graceDays: Int
        var durationMinutes: Int
        var status: PendingChargeProposalStatus

        init(code: String, title: String, maximum: Double, budget: Double, ratio: Double, acuity: Int, channel: String, amount: Double, approved: Bool, graceDays: Int, durationMinutes: Int, status: PendingChargeProposalStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.budget = budget
            self.ratio = ratio
            self.acuity = acuity
            self.channel = channel
            self.amount = amount
            self.approved = approved
            self.graceDays = graceDays
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: PendingChargeProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == PendingChargeProposalStatus.inProgress || next == PendingChargeProposalStatus.completed
            case .inProgress:
                return next == PendingChargeProposalStatus.completed
            case .completed:
                return next == PendingChargeProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingChargeProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending charge proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return ((Double(graceDays) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingChargeProposal {
            return PendingChargeProposal(
                code: code,
                title: title,
                maximum: maximum,
                budget: budget,
                ratio: ratio,
                acuity: acuity,
                channel: channel,
                amount: amount,
                approved: approved,
                graceDays: graceDays,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a pending charge proposal in status planned.
    static func newPendingChargeProposal(_ code: String, title: String) -> PendingChargeProposal {
        return PendingChargeProposal(
            code: code,
            title: title,
            maximum: 0.0,
            budget: 0.0,
            ratio: 0.0,
            acuity: 0,
            channel: "",
            amount: 0.0,
            approved: false,
            graceDays: 0,
            durationMinutes: 0,
            status: PendingChargeProposalStatus.planned
        )
    }
}
