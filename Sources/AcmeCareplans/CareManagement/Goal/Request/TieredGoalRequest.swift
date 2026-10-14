import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered goal request is in its life cycle.
    enum TieredGoalRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered goal request, with what the planners need to act on it.
    final class TieredGoalRequest {
        var code: String
        var title: String
        var tags: [String]
        var discount: Double
        var score: Double
        var status: TieredGoalRequestStatus

        init(code: String, title: String, tags: [String], discount: Double, score: Double, status: TieredGoalRequestStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.discount = discount
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

        func canMoveTo(_ next: TieredGoalRequestStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredGoalRequestStatus.published
            case .validated:
                return next == TieredGoalRequestStatus.published
            case .published:
                return next == TieredGoalRequestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredGoalRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered goal request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return (discount * score * 100).rounded() / 100
        }

        func copyValue() -> TieredGoalRequest {
            return TieredGoalRequest(
                code: code,
                title: title,
                tags: tags,
                discount: discount,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered goal request in status created.
    static func newTieredGoalRequest(_ code: String, title: String) -> TieredGoalRequest {
        return TieredGoalRequest(
            code: code,
            title: title,
            tags: [],
            discount: 0.0,
            score: 0.0,
            status: TieredGoalRequestStatus.created
        )
    }
}
