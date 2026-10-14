import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure milestone is in its life cycle.
    enum ClosureMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A closure milestone as the closure team keeps it.
    final class ClosureMilestone {
        var code: String
        var title: String
        var payer: String
        var externalRef: String
        var name: String
        var score: Double
        var status: ClosureMilestoneStatus

        init(code: String, title: String, payer: String, externalRef: String, name: String, score: Double, status: ClosureMilestoneStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.externalRef = externalRef
            self.name = name
            self.score = score
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

        func canMoveTo(_ next: ClosureMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClosureMilestoneStatus.pending || next == ClosureMilestoneStatus.suspended
            case .pending:
                return next == ClosureMilestoneStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ClosureMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ClosureMilestone {
            return ClosureMilestone(
                code: code,
                title: title,
                payer: payer,
                externalRef: externalRef,
                name: name,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a closure milestone in status draft.
    static func newClosureMilestone(_ code: String, title: String) -> ClosureMilestone {
        return ClosureMilestone(
            code: code,
            title: title,
            payer: "",
            externalRef: "",
            name: "",
            score: 0.0,
            status: ClosureMilestoneStatus.draft
        )
    }
}
