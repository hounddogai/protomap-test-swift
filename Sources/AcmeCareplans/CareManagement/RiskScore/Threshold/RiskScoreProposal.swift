import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score proposal is in its life cycle.
    enum RiskScoreProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A risk score proposal. Its code is unique within a tenant.
    final class RiskScoreProposal {
        var code: String
        var name: String
        var rate: Double
        var margin: Double
        var clinicianID: String
        var currency: String
        var ratio: Double
        var locale: String
        var status: RiskScoreProposalStatus

        init(code: String, name: String, rate: Double, margin: Double, clinicianID: String, currency: String, ratio: Double, locale: String, status: RiskScoreProposalStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.margin = margin
            self.clinicianID = clinicianID
            self.currency = currency
            self.ratio = ratio
            self.locale = locale
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

        func canMoveTo(_ next: RiskScoreProposalStatus) -> Bool {
            switch status {
            case .planned:
                return next == RiskScoreProposalStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RiskScoreProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("risk score proposal") \(code)"
        }

        func projectedExposure() -> Double {
            return (margin * ratio * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreProposal {
            return RiskScoreProposal(
                code: code,
                name: name,
                rate: rate,
                margin: margin,
                clinicianID: clinicianID,
                currency: currency,
                ratio: ratio,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a risk score proposal in status planned.
    static func newRiskScoreProposal(_ code: String, name: String) -> RiskScoreProposal {
        return RiskScoreProposal(
            code: code,
            name: name,
            rate: 0.0,
            margin: 0.0,
            clinicianID: "",
            currency: "",
            ratio: 0.0,
            locale: "",
            status: RiskScoreProposalStatus.planned
        )
    }
}
