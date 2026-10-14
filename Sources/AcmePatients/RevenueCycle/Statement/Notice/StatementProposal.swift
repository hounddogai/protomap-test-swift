import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement proposal is in its life cycle.
    enum StatementProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One statement proposal, with what the planners need to act on it.
    final class StatementProposal {
        var code: String
        var name: String
        var clinicianID: String
        var channel: String
        var graceDays: Int
        var status: StatementProposalStatus

        init(code: String, name: String, clinicianID: String, channel: String, graceDays: Int, status: StatementProposalStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.channel = channel
            self.graceDays = graceDays
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

        func canMoveTo(_ next: StatementProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StatementProposalStatus.suspended || next == StatementProposalStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StatementProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement proposal") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> StatementProposal {
            return StatementProposal(
                code: code,
                name: name,
                clinicianID: clinicianID,
                channel: channel,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a statement proposal in status draft.
    static func newStatementProposal(_ code: String, name: String) -> StatementProposal {
        return StatementProposal(
            code: code,
            name: name,
            clinicianID: "",
            channel: "",
            graceDays: 0,
            status: StatementProposalStatus.draft
        )
    }
}
