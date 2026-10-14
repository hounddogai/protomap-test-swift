import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted substitution proposal is in its life cycle.
    enum WeightedSubstitutionProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted substitution proposal and its current status.
    final class WeightedSubstitutionProposal {
        var code: String
        var title: String
        var country: String
        var payer: String
        var timezone: String
        var facility: String
        var reviewer: String
        var score: Double
        var status: WeightedSubstitutionProposalStatus

        init(code: String, title: String, country: String, payer: String, timezone: String, facility: String, reviewer: String, score: Double, status: WeightedSubstitutionProposalStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.payer = payer
            self.timezone = timezone
            self.facility = facility
            self.reviewer = reviewer
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedSubstitutionProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedSubstitutionProposalStatus.granted
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: WeightedSubstitutionProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted substitution proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted substitution proposal") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> WeightedSubstitutionProposal {
            return WeightedSubstitutionProposal(
                code: code,
                title: title,
                country: country,
                payer: payer,
                timezone: timezone,
                facility: facility,
                reviewer: reviewer,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted substitution proposal in status requested.
    static func newWeightedSubstitutionProposal(_ code: String, title: String) -> WeightedSubstitutionProposal {
        return WeightedSubstitutionProposal(
            code: code,
            title: title,
            country: "",
            payer: "",
            timezone: "",
            facility: "",
            reviewer: "",
            score: 0.0,
            status: WeightedSubstitutionProposalStatus.requested
        )
    }
}
