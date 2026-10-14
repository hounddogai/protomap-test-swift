import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling read proposal is in its life cycle.
    enum RollingReadProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling read proposal. Its code is unique within a tenant.
    final class RollingReadProposal {
        var code: String
        var title: String
        var currency: String
        var cost: Double
        var contactEmail: String
        var status: RollingReadProposalStatus

        init(code: String, title: String, currency: String, cost: Double, contactEmail: String, status: RollingReadProposalStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.cost = cost
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: RollingReadProposalStatus) -> Bool {
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
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RollingReadProposalStatus.cancelled
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

        func moveTo(_ next: RollingReadProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling read proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> RollingReadProposal {
            return RollingReadProposal(
                code: code,
                title: title,
                currency: currency,
                cost: cost,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling read proposal in status planned.
    static func newRollingReadProposal(_ code: String, title: String) -> RollingReadProposal {
        return RollingReadProposal(
            code: code,
            title: title,
            currency: "",
            cost: 0.0,
            contactEmail: "",
            status: RollingReadProposalStatus.planned
        )
    }
}
