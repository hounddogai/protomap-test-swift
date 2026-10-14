import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal credential proposal is in its life cycle.
    enum SeasonalCredentialProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal credential proposal, with what the planners need to act on it.
    final class SeasonalCredentialProposal {
        var code: String
        var title: String
        var updatedAt: Int
        var acuity: Int
        var source: String
        var name: String
        var diagnosisCode: String
        var createdAt: Int
        var status: SeasonalCredentialProposalStatus

        init(code: String, title: String, updatedAt: Int, acuity: Int, source: String, name: String, diagnosisCode: String, createdAt: Int, status: SeasonalCredentialProposalStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.source = source
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
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

        func canMoveTo(_ next: SeasonalCredentialProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalCredentialProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCredentialProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal credential proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(acuity) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCredentialProposal {
            return SeasonalCredentialProposal(
                code: code,
                title: title,
                updatedAt: updatedAt,
                acuity: acuity,
                source: source,
                name: name,
                diagnosisCode: diagnosisCode,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a seasonal credential proposal in status open.
    static func newSeasonalCredentialProposal(_ code: String, title: String) -> SeasonalCredentialProposal {
        return SeasonalCredentialProposal(
            code: code,
            title: title,
            updatedAt: 0,
            acuity: 0,
            source: "",
            name: "",
            diagnosisCode: "",
            createdAt: 0,
            status: SeasonalCredentialProposalStatus.`open`
        )
    }
}
