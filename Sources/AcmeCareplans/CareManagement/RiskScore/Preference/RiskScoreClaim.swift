import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score claim is in its life cycle.
    enum RiskScoreClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One risk score claim, with what the planners need to act on it.
    final class RiskScoreClaim {
        var code: String
        var label: String
        var country: String
        var notes: String
        var description: String
        var amount: Double
        var status: RiskScoreClaimStatus

        init(code: String, label: String, country: String, notes: String, description: String, amount: Double, status: RiskScoreClaimStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.notes = notes
            self.description = description
            self.amount = amount
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

        func canMoveTo(_ next: RiskScoreClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RiskScoreClaimStatus.published || next == RiskScoreClaimStatus.retired
            case .published:
                return next == RiskScoreClaimStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RiskScoreClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RiskScoreClaim {
            return RiskScoreClaim(
                code: code,
                label: label,
                country: country,
                notes: notes,
                description: description,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a risk score claim in status created.
    static func newRiskScoreClaim(_ code: String, label: String) -> RiskScoreClaim {
        return RiskScoreClaim(
            code: code,
            label: label,
            country: "",
            notes: "",
            description: "",
            amount: 0.0,
            status: RiskScoreClaimStatus.created
        )
    }
}
