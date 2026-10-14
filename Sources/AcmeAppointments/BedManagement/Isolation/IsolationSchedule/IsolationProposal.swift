import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation proposal is in its life cycle.
    enum IsolationProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One isolation proposal, with what the planners need to act on it.
    final class IsolationProposal {
        var code: String
        var title: String
        var tags: [String]
        var approved: Bool
        var quantity: Int
        var discount: Double
        var status: IsolationProposalStatus

        init(code: String, title: String, tags: [String], approved: Bool, quantity: Int, discount: Double, status: IsolationProposalStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.approved = approved
            self.quantity = quantity
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == IsolationProposalStatus.inReview || next == IsolationProposalStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == IsolationProposalStatus.reopened || next == IsolationProposalStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: IsolationProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return (discount * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> IsolationProposal {
            return IsolationProposal(
                code: code,
                title: title,
                tags: tags,
                approved: approved,
                quantity: quantity,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation proposal in status open.
    static func newIsolationProposal(_ code: String, title: String) -> IsolationProposal {
        return IsolationProposal(
            code: code,
            title: title,
            tags: [],
            approved: false,
            quantity: 0,
            discount: 0.0,
            status: IsolationProposalStatus.`open`
        )
    }
}
