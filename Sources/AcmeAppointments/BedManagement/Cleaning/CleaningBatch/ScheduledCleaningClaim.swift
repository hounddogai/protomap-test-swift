import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled cleaning claim is in its life cycle.
    enum ScheduledCleaningClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled cleaning claim and its current status.
    final class ScheduledCleaningClaim {
        var code: String
        var name: String
        var updatedAt: Int
        var score: Double
        var refills: Int
        var status: ScheduledCleaningClaimStatus

        init(code: String, name: String, updatedAt: Int, score: Double, refills: Int, status: ScheduledCleaningClaimStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.score = score
            self.refills = refills
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

        func canMoveTo(_ next: ScheduledCleaningClaimStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ScheduledCleaningClaimStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ScheduledCleaningClaimStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCleaningClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled cleaning claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return (Double(updatedAt) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCleaningClaim {
            return ScheduledCleaningClaim(
                code: code,
                name: name,
                updatedAt: updatedAt,
                score: score,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled cleaning claim in status open.
    static func newScheduledCleaningClaim(_ code: String, name: String) -> ScheduledCleaningClaim {
        return ScheduledCleaningClaim(
            code: code,
            name: name,
            updatedAt: 0,
            score: 0.0,
            refills: 0,
            status: ScheduledCleaningClaimStatus.`open`
        )
    }
}
