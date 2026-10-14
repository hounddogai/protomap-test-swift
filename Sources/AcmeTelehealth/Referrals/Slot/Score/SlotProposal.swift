import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot proposal is in its life cycle.
    enum SlotProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A slot proposal as the slot team keeps it.
    final class SlotProposal {
        var code: String
        var title: String
        var ratio: Double
        var contactEmail: String
        var rate: Double
        var ceiling: Double
        var maximum: Double
        var status: SlotProposalStatus

        init(code: String, title: String, ratio: Double, contactEmail: String, rate: Double, ceiling: Double, maximum: Double, status: SlotProposalStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.rate = rate
            self.ceiling = ceiling
            self.maximum = maximum
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

        func canMoveTo(_ next: SlotProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SlotProposalStatus.resolved
            case .inReview:
                return next == SlotProposalStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SlotProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedLoad() -> Double {
            return ((ceiling - rate) * 100).rounded() / 100
        }

        func copyValue() -> SlotProposal {
            return SlotProposal(
                code: code,
                title: title,
                ratio: ratio,
                contactEmail: contactEmail,
                rate: rate,
                ceiling: ceiling,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot proposal in status open.
    static func newSlotProposal(_ code: String, title: String) -> SlotProposal {
        return SlotProposal(
            code: code,
            title: title,
            ratio: 0.0,
            contactEmail: "",
            rate: 0.0,
            ceiling: 0.0,
            maximum: 0.0,
            status: SlotProposalStatus.`open`
        )
    }
}
