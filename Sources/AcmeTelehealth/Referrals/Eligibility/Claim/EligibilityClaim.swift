import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility claim is in its life cycle.
    enum EligibilityClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a eligibility claim and its current status.
    final class EligibilityClaim {
        var code: String
        var title: String
        var rate: Double
        var threshold: Double
        var sequence: Int
        var status: EligibilityClaimStatus

        init(code: String, title: String, rate: Double, threshold: Double, sequence: Int, status: EligibilityClaimStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.threshold = threshold
            self.sequence = sequence
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

        func canMoveTo(_ next: EligibilityClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == EligibilityClaimStatus.active || next == EligibilityClaimStatus.suspended
            case .active:
                return next == EligibilityClaimStatus.suspended || next == EligibilityClaimStatus.closed
            case .suspended:
                return next == EligibilityClaimStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return (Double(sequence) * rate * 100).rounded() / 100
        }

        func copyValue() -> EligibilityClaim {
            return EligibilityClaim(
                code: code,
                title: title,
                rate: rate,
                threshold: threshold,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a eligibility claim in status draft.
    static func newEligibilityClaim(_ code: String, title: String) -> EligibilityClaim {
        return EligibilityClaim(
            code: code,
            title: title,
            rate: 0.0,
            threshold: 0.0,
            sequence: 0,
            status: EligibilityClaimStatus.draft
        )
    }
}
