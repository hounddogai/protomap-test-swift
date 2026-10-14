import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach proposal is in its life cycle.
    enum OutreachProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A outreach proposal as the outreach team keeps it.
    final class OutreachProposal {
        var code: String
        var name: String
        var cost: Double
        var phone: String
        var externalRef: String
        var tags: [String]
        var archived: Bool
        var endsAt: Int
        var status: OutreachProposalStatus

        init(code: String, name: String, cost: Double, phone: String, externalRef: String, tags: [String], archived: Bool, endsAt: Int, status: OutreachProposalStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.phone = phone
            self.externalRef = externalRef
            self.tags = tags
            self.archived = archived
            self.endsAt = endsAt
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

        func canMoveTo(_ next: OutreachProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == OutreachProposalStatus.resolved || next == OutreachProposalStatus.reopened
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == OutreachProposalStatus.reopened
            case .reopened:
                return next == OutreachProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) + cost) * 100).rounded() / 100
        }

        func copyValue() -> OutreachProposal {
            return OutreachProposal(
                code: code,
                name: name,
                cost: cost,
                phone: phone,
                externalRef: externalRef,
                tags: tags,
                archived: archived,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach proposal in status open.
    static func newOutreachProposal(_ code: String, name: String) -> OutreachProposal {
        return OutreachProposal(
            code: code,
            name: name,
            cost: 0.0,
            phone: "",
            externalRef: "",
            tags: [],
            archived: false,
            endsAt: 0,
            status: OutreachProposalStatus.`open`
        )
    }
}
