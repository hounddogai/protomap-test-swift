import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback goal claim is in its life cycle.
    enum FallbackGoalClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a fallback goal claim and its current status.
    final class FallbackGoalClaim {
        var code: String
        var title: String
        var region: String
        var attempts: Int
        var ownerID: String
        var acuity: Int
        var bed: String
        var status: FallbackGoalClaimStatus

        init(code: String, title: String, region: String, attempts: Int, ownerID: String, acuity: Int, bed: String, status: FallbackGoalClaimStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.attempts = attempts
            self.ownerID = ownerID
            self.acuity = acuity
            self.bed = bed
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

        func canMoveTo(_ next: FallbackGoalClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackGoalClaimStatus.scheduled
            case .scheduled:
                return next == FallbackGoalClaimStatus.completed || next == FallbackGoalClaimStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: FallbackGoalClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback goal claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netValue() -> Double {
            return ((Double(attempts) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackGoalClaim {
            return FallbackGoalClaim(
                code: code,
                title: title,
                region: region,
                attempts: attempts,
                ownerID: ownerID,
                acuity: acuity,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback goal claim in status planned.
    static func newFallbackGoalClaim(_ code: String, title: String) -> FallbackGoalClaim {
        return FallbackGoalClaim(
            code: code,
            title: title,
            region: "",
            attempts: 0,
            ownerID: "",
            acuity: 0,
            bed: "",
            status: FallbackGoalClaimStatus.planned
        )
    }
}
