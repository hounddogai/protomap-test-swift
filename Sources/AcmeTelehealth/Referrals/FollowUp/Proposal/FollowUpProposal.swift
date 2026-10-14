import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up proposal is in its life cycle.
    enum FollowUpProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a follow up proposal and its current status.
    final class FollowUpProposal {
        var code: String
        var title: String
        var ceiling: Double
        var encounterID: String
        var startsAt: Int
        var limit: Int
        var endsAt: Int
        var refills: Int
        var status: FollowUpProposalStatus

        init(code: String, title: String, ceiling: Double, encounterID: String, startsAt: Int, limit: Int, endsAt: Int, refills: Int, status: FollowUpProposalStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.limit = limit
            self.endsAt = endsAt
            self.refills = refills
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

        func canMoveTo(_ next: FollowUpProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FollowUpProposalStatus.cancelled
            case .completed:
                return next == FollowUpProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return ((Double(startsAt) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpProposal {
            return FollowUpProposal(
                code: code,
                title: title,
                ceiling: ceiling,
                encounterID: encounterID,
                startsAt: startsAt,
                limit: limit,
                endsAt: endsAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a follow up proposal in status planned.
    static func newFollowUpProposal(_ code: String, title: String) -> FollowUpProposal {
        return FollowUpProposal(
            code: code,
            title: title,
            ceiling: 0.0,
            encounterID: "",
            startsAt: 0,
            limit: 0,
            endsAt: 0,
            refills: 0,
            status: FollowUpProposalStatus.planned
        )
    }
}
