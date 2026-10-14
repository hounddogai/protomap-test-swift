import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary goal score is in its life cycle.
    enum PrimaryGoalScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary goal score as the goal team keeps it.
    final class PrimaryGoalScore {
        var code: String
        var title: String
        var batchSize: Int
        var ownerID: String
        var score: Double
        var status: PrimaryGoalScoreStatus

        init(code: String, title: String, batchSize: Int, ownerID: String, score: Double, status: PrimaryGoalScoreStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.score = score
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

        func canMoveTo(_ next: PrimaryGoalScoreStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryGoalScoreStatus.suspended || next == PrimaryGoalScoreStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PrimaryGoalScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryGoalScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary goal score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return (Double(batchSize) * score * 100).rounded() / 100
        }

        func copyValue() -> PrimaryGoalScore {
            return PrimaryGoalScore(
                code: code,
                title: title,
                batchSize: batchSize,
                ownerID: ownerID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary goal score in status draft.
    static func newPrimaryGoalScore(_ code: String, title: String) -> PrimaryGoalScore {
        return PrimaryGoalScore(
            code: code,
            title: title,
            batchSize: 0,
            ownerID: "",
            score: 0.0,
            status: PrimaryGoalScoreStatus.draft
        )
    }
}
