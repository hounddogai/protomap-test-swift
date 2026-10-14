import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set proposal is in its life cycle.
    enum OrderSetProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set proposal as the order set team keeps it.
    final class OrderSetProposal {
        var code: String
        var name: String
        var allergy: String
        var amount: Double
        var archived: Bool
        var locale: String
        var ratio: Double
        var retries: Int
        var tags: [String]
        var acuity: Int
        var status: OrderSetProposalStatus

        init(code: String, name: String, allergy: String, amount: Double, archived: Bool, locale: String, ratio: Double, retries: Int, tags: [String], acuity: Int, status: OrderSetProposalStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.amount = amount
            self.archived = archived
            self.locale = locale
            self.ratio = ratio
            self.retries = retries
            self.tags = tags
            self.acuity = acuity
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

        func canMoveTo(_ next: OrderSetProposalStatus) -> Bool {
            switch status {
            case .planned:
                return next == OrderSetProposalStatus.inProgress || next == OrderSetProposalStatus.completed
            case .scheduled:
                return next == OrderSetProposalStatus.completed
            case .inProgress:
                return next == OrderSetProposalStatus.cancelled
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

        func moveTo(_ next: OrderSetProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(retries) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetProposal {
            return OrderSetProposal(
                code: code,
                name: name,
                allergy: allergy,
                amount: amount,
                archived: archived,
                locale: locale,
                ratio: ratio,
                retries: retries,
                tags: tags,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a order set proposal in status planned.
    static func newOrderSetProposal(_ code: String, name: String) -> OrderSetProposal {
        return OrderSetProposal(
            code: code,
            name: name,
            allergy: "",
            amount: 0.0,
            archived: false,
            locale: "",
            ratio: 0.0,
            retries: 0,
            tags: [],
            acuity: 0,
            status: OrderSetProposalStatus.planned
        )
    }
}
