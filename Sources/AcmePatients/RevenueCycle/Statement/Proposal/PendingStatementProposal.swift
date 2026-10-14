import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending statement proposal is in its life cycle.
    enum PendingStatementProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending statement proposal, with what the planners need to act on it.
    final class PendingStatementProposal {
        var code: String
        var name: String
        var currency: String
        var allergy: String
        var active: Bool
        var ownerID: String
        var visitMinutes: Int
        var procedureCode: String
        var status: PendingStatementProposalStatus

        init(code: String, name: String, currency: String, allergy: String, active: Bool, ownerID: String, visitMinutes: Int, procedureCode: String, status: PendingStatementProposalStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.allergy = allergy
            self.active = active
            self.ownerID = ownerID
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingStatementProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingStatementProposalStatus.ready
            case .warming:
                return next == PendingStatementProposalStatus.ready
            case .ready:
                return next == PendingStatementProposalStatus.draining || next == PendingStatementProposalStatus.stopped
            case .draining:
                return next == PendingStatementProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingStatementProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending statement proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> PendingStatementProposal {
            return PendingStatementProposal(
                code: code,
                name: name,
                currency: currency,
                allergy: allergy,
                active: active,
                ownerID: ownerID,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending statement proposal in status idle.
    static func newPendingStatementProposal(_ code: String, name: String) -> PendingStatementProposal {
        return PendingStatementProposal(
            code: code,
            name: name,
            currency: "",
            allergy: "",
            active: false,
            ownerID: "",
            visitMinutes: 0,
            procedureCode: "",
            status: PendingStatementProposalStatus.idle
        )
    }
}
