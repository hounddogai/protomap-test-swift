import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy charge score is in its life cycle.
    enum LegacyChargeScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy charge score. Its code is unique within a tenant.
    final class LegacyChargeScore {
        var code: String
        var name: String
        var startsAt: Int
        var threshold: Double
        var attempts: Int
        var status: LegacyChargeScoreStatus

        init(code: String, name: String, startsAt: Int, threshold: Double, attempts: Int, status: LegacyChargeScoreStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.threshold = threshold
            self.attempts = attempts
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

        func canMoveTo(_ next: LegacyChargeScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyChargeScoreStatus.resolved || next == LegacyChargeScoreStatus.reopened
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
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyChargeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy charge score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return (Double(startsAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> LegacyChargeScore {
            return LegacyChargeScore(
                code: code,
                name: name,
                startsAt: startsAt,
                threshold: threshold,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy charge score in status open.
    static func newLegacyChargeScore(_ code: String, name: String) -> LegacyChargeScore {
        return LegacyChargeScore(
            code: code,
            name: name,
            startsAt: 0,
            threshold: 0.0,
            attempts: 0,
            status: LegacyChargeScoreStatus.`open`
        )
    }
}
