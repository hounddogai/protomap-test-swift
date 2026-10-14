import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall proposal is in its life cycle.
    enum PendingRecallProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending recall proposal, with what the planners need to act on it.
    final class PendingRecallProposal {
        var code: String
        var title: String
        var externalRef: String
        var discount: Double
        var capacity: Int
        var margin: Double
        var amount: Double
        var status: PendingRecallProposalStatus

        init(code: String, title: String, externalRef: String, discount: Double, capacity: Int, margin: Double, amount: Double, status: PendingRecallProposalStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.discount = discount
            self.capacity = capacity
            self.margin = margin
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingRecallProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingRecallProposalStatus.ready
            case .warming:
                return next == PendingRecallProposalStatus.ready || next == PendingRecallProposalStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PendingRecallProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingRecallProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return (amount * margin * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallProposal {
            return PendingRecallProposal(
                code: code,
                title: title,
                externalRef: externalRef,
                discount: discount,
                capacity: capacity,
                margin: margin,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending recall proposal in status idle.
    static func newPendingRecallProposal(_ code: String, title: String) -> PendingRecallProposal {
        return PendingRecallProposal(
            code: code,
            title: title,
            externalRef: "",
            discount: 0.0,
            capacity: 0,
            margin: 0.0,
            amount: 0.0,
            status: PendingRecallProposalStatus.idle
        )
    }
}
