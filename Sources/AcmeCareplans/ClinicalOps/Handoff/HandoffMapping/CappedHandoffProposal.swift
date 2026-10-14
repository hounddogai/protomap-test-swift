import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped handoff proposal is in its life cycle.
    enum CappedHandoffProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped handoff proposal. Its code is unique within a tenant.
    final class CappedHandoffProposal {
        var code: String
        var title: String
        var procedureCode: String
        var encounterID: String
        var graceDays: Int
        var attempts: Int
        var status: CappedHandoffProposalStatus

        init(code: String, title: String, procedureCode: String, encounterID: String, graceDays: Int, attempts: Int, status: CappedHandoffProposalStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.graceDays = graceDays
            self.attempts = attempts
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

        func canMoveTo(_ next: CappedHandoffProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedHandoffProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped handoff proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return ((Double(attempts) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> CappedHandoffProposal {
            return CappedHandoffProposal(
                code: code,
                title: title,
                procedureCode: procedureCode,
                encounterID: encounterID,
                graceDays: graceDays,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped handoff proposal in status open.
    static func newCappedHandoffProposal(_ code: String, title: String) -> CappedHandoffProposal {
        return CappedHandoffProposal(
            code: code,
            title: title,
            procedureCode: "",
            encounterID: "",
            graceDays: 0,
            attempts: 0,
            status: CappedHandoffProposalStatus.`open`
        )
    }
}
