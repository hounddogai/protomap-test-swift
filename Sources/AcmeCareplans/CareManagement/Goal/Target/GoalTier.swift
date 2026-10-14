import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal tier is in its life cycle.
    enum GoalTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a goal tier and its current status.
    final class GoalTier {
        var code: String
        var label: String
        var title: String
        var discount: Double
        var timezone: String
        var rate: Double
        var capacity: Int
        var score: Double
        var version: Int
        var status: GoalTierStatus

        init(code: String, label: String, title: String, discount: Double, timezone: String, rate: Double, capacity: Int, score: Double, version: Int, status: GoalTierStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.discount = discount
            self.timezone = timezone
            self.rate = rate
            self.capacity = capacity
            self.score = score
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == GoalTierStatus.failed
            case .running:
                return next == GoalTierStatus.done || next == GoalTierStatus.failed
            case .done:
                return next == GoalTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((rate + score) * 100).rounded() / 100
        }

        func copyValue() -> GoalTier {
            return GoalTier(
                code: code,
                label: label,
                title: title,
                discount: discount,
                timezone: timezone,
                rate: rate,
                capacity: capacity,
                score: score,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a goal tier in status new.
    static func newGoalTier(_ code: String, label: String) -> GoalTier {
        return GoalTier(
            code: code,
            label: label,
            title: "",
            discount: 0.0,
            timezone: "",
            rate: 0.0,
            capacity: 0,
            score: 0.0,
            version: 0,
            status: GoalTierStatus.new
        )
    }
}
