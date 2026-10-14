import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient read proposal is in its life cycle.
    enum LenientReadProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a lenient read proposal and its current status.
    final class LenientReadProposal {
        var code: String
        var title: String
        var sequence: Int
        var summary: String
        var visitMinutes: Int
        var contactEmail: String
        var reviewer: String
        var score: Double
        var archived: Bool
        var retries: Int
        var status: LenientReadProposalStatus

        init(code: String, title: String, sequence: Int, summary: String, visitMinutes: Int, contactEmail: String, reviewer: String, score: Double, archived: Bool, retries: Int, status: LenientReadProposalStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.score = score
            self.archived = archived
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientReadProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == LenientReadProposalStatus.published
            case .validated:
                return next == LenientReadProposalStatus.published || next == LenientReadProposalStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LenientReadProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient read proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient read proposal") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((score - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReadProposal {
            return LenientReadProposal(
                code: code,
                title: title,
                sequence: sequence,
                summary: summary,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                reviewer: reviewer,
                score: score,
                archived: archived,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient read proposal in status created.
    static func newLenientReadProposal(_ code: String, title: String) -> LenientReadProposal {
        return LenientReadProposal(
            code: code,
            title: title,
            sequence: 0,
            summary: "",
            visitMinutes: 0,
            contactEmail: "",
            reviewer: "",
            score: 0.0,
            archived: false,
            retries: 0,
            status: LenientReadProposalStatus.created
        )
    }
}
