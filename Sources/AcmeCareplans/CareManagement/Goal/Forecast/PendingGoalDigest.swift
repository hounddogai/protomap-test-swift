import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending goal digest is in its life cycle.
    enum PendingGoalDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One pending goal digest, with what the planners need to act on it.
    final class PendingGoalDigest {
        var code: String
        var title: String
        var summary: String
        var ownerID: String
        var description: String
        var score: Double
        var status: PendingGoalDigestStatus

        init(code: String, title: String, summary: String, ownerID: String, description: String, score: Double, status: PendingGoalDigestStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.ownerID = ownerID
            self.description = description
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

        func canMoveTo(_ next: PendingGoalDigestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingGoalDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending goal digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending goal digest") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PendingGoalDigest {
            return PendingGoalDigest(
                code: code,
                title: title,
                summary: summary,
                ownerID: ownerID,
                description: description,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending goal digest in status requested.
    static func newPendingGoalDigest(_ code: String, title: String) -> PendingGoalDigest {
        return PendingGoalDigest(
            code: code,
            title: title,
            summary: "",
            ownerID: "",
            description: "",
            score: 0.0,
            status: PendingGoalDigestStatus.requested
        )
    }
}
