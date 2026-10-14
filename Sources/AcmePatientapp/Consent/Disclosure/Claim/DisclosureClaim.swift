import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure claim is in its life cycle.
    enum DisclosureClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One disclosure claim, with what the planners need to act on it.
    final class DisclosureClaim {
        var code: String
        var name: String
        var country: String
        var score: Double
        var clinicianID: String
        var status: DisclosureClaimStatus

        init(code: String, name: String, country: String, score: Double, clinicianID: String, status: DisclosureClaimStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.score = score
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DisclosureClaimStatus.rejected || next == DisclosureClaimStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DisclosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> DisclosureClaim {
            return DisclosureClaim(
                code: code,
                name: name,
                country: country,
                score: score,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a disclosure claim in status proposed.
    static func newDisclosureClaim(_ code: String, name: String) -> DisclosureClaim {
        return DisclosureClaim(
            code: code,
            name: name,
            country: "",
            score: 0.0,
            clinicianID: "",
            status: DisclosureClaimStatus.proposed
        )
    }
}
