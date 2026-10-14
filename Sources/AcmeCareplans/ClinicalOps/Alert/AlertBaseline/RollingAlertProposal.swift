import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling alert proposal is in its life cycle.
    enum RollingAlertProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a rolling alert proposal and its current status.
    final class RollingAlertProposal {
        var code: String
        var title: String
        var diagnosisCode: String
        var reviewer: String
        var endsAt: Int
        var source: String
        var encounterID: String
        var status: RollingAlertProposalStatus

        init(code: String, title: String, diagnosisCode: String, reviewer: String, endsAt: Int, source: String, encounterID: String, status: RollingAlertProposalStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.source = source
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RollingAlertProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RollingAlertProposalStatus.suspended || next == RollingAlertProposalStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RollingAlertProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAlertProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling alert proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> RollingAlertProposal {
            return RollingAlertProposal(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                reviewer: reviewer,
                endsAt: endsAt,
                source: source,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling alert proposal in status draft.
    static func newRollingAlertProposal(_ code: String, title: String) -> RollingAlertProposal {
        return RollingAlertProposal(
            code: code,
            title: title,
            diagnosisCode: "",
            reviewer: "",
            endsAt: 0,
            source: "",
            encounterID: "",
            status: RollingAlertProposalStatus.draft
        )
    }
}
