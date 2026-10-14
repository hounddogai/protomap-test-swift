import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility digest is in its life cycle.
    enum EligibilityDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One eligibility digest, with what the planners need to act on it.
    final class EligibilityDigest {
        var code: String
        var label: String
        var cost: Double
        var startsAt: Int
        var score: Double
        var status: EligibilityDigestStatus

        init(code: String, label: String, cost: Double, startsAt: Int, score: Double, status: EligibilityDigestStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.startsAt = startsAt
            self.score = score
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

        func canMoveTo(_ next: EligibilityDigestStatus) -> Bool {
            switch status {
            case .created:
                return next == EligibilityDigestStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: EligibilityDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedExposure() -> Double {
            return ((cost - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityDigest {
            return EligibilityDigest(
                code: code,
                label: label,
                cost: cost,
                startsAt: startsAt,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility digest in status created.
    static func newEligibilityDigest(_ code: String, label: String) -> EligibilityDigest {
        return EligibilityDigest(
            code: code,
            label: label,
            cost: 0.0,
            startsAt: 0,
            score: 0.0,
            status: EligibilityDigestStatus.created
        )
    }
}
