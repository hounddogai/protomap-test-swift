import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy disclosure claim is in its life cycle.
    enum LegacyDisclosureClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One legacy disclosure claim, with what the planners need to act on it.
    final class LegacyDisclosureClaim {
        var code: String
        var label: String
        var contactEmail: String
        var procedureCode: String
        var score: Double
        var cost: Double
        var status: LegacyDisclosureClaimStatus

        init(code: String, label: String, contactEmail: String, procedureCode: String, score: Double, cost: Double, status: LegacyDisclosureClaimStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.procedureCode = procedureCode
            self.score = score
            self.cost = cost
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

        func canMoveTo(_ next: LegacyDisclosureClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyDisclosureClaimStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == LegacyDisclosureClaimStatus.cancelled
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

        func moveTo(_ next: LegacyDisclosureClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy disclosure claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy disclosure claim") \(code)"
        }

        func netVolume() -> Double {
            return ((cost + score) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDisclosureClaim {
            return LegacyDisclosureClaim(
                code: code,
                label: label,
                contactEmail: contactEmail,
                procedureCode: procedureCode,
                score: score,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy disclosure claim in status planned.
    static func newLegacyDisclosureClaim(_ code: String, label: String) -> LegacyDisclosureClaim {
        return LegacyDisclosureClaim(
            code: code,
            label: label,
            contactEmail: "",
            procedureCode: "",
            score: 0.0,
            cost: 0.0,
            status: LegacyDisclosureClaimStatus.planned
        )
    }
}
