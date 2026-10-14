import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted result score is in its life cycle.
    enum WeightedResultScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a weighted result score and its current status.
    final class WeightedResultScore {
        var code: String
        var name: String
        var timezone: String
        var score: Double
        var quantity: Int
        var sequence: Int
        var status: WeightedResultScoreStatus

        init(code: String, name: String, timezone: String, score: Double, quantity: Int, sequence: Int, status: WeightedResultScoreStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.score = score
            self.quantity = quantity
            self.sequence = sequence
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

        func canMoveTo(_ next: WeightedResultScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WeightedResultScoreStatus.inReview || next == WeightedResultScoreStatus.reopened
            case .inReview:
                return next == WeightedResultScoreStatus.resolved || next == WeightedResultScoreStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
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

        func moveTo(_ next: WeightedResultScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted result score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return ((Double(quantity) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedResultScore {
            return WeightedResultScore(
                code: code,
                name: name,
                timezone: timezone,
                score: score,
                quantity: quantity,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted result score in status open.
    static func newWeightedResultScore(_ code: String, name: String) -> WeightedResultScore {
        return WeightedResultScore(
            code: code,
            name: name,
            timezone: "",
            score: 0.0,
            quantity: 0,
            sequence: 0,
            status: WeightedResultScoreStatus.`open`
        )
    }
}
