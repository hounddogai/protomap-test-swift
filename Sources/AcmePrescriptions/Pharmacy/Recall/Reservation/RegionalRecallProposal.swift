import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional recall proposal is in its life cycle.
    enum RegionalRecallProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional recall proposal and its current status.
    final class RegionalRecallProposal {
        var code: String
        var name: String
        var cost: Double
        var encounterID: String
        var copay: Double
        var procedureCode: String
        var durationMinutes: Int
        var payer: String
        var reviewer: String
        var graceDays: Int
        var status: RegionalRecallProposalStatus

        init(code: String, name: String, cost: Double, encounterID: String, copay: Double, procedureCode: String, durationMinutes: Int, payer: String, reviewer: String, graceDays: Int, status: RegionalRecallProposalStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.encounterID = encounterID
            self.copay = copay
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.reviewer = reviewer
            self.graceDays = graceDays
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

        func canMoveTo(_ next: RegionalRecallProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalRecallProposalStatus.reopened || next == RegionalRecallProposalStatus.archived
            case .inReview:
                return next == RegionalRecallProposalStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalRecallProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalRecallProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional recall proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional recall proposal") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((cost + copay) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRecallProposal {
            return RegionalRecallProposal(
                code: code,
                name: name,
                cost: cost,
                encounterID: encounterID,
                copay: copay,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                payer: payer,
                reviewer: reviewer,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional recall proposal in status open.
    static func newRegionalRecallProposal(_ code: String, name: String) -> RegionalRecallProposal {
        return RegionalRecallProposal(
            code: code,
            name: name,
            cost: 0.0,
            encounterID: "",
            copay: 0.0,
            procedureCode: "",
            durationMinutes: 0,
            payer: "",
            reviewer: "",
            graceDays: 0,
            status: RegionalRecallProposalStatus.`open`
        )
    }
}
