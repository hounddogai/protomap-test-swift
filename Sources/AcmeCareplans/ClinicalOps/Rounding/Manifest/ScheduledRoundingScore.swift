import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled rounding score is in its life cycle.
    enum ScheduledRoundingScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled rounding score as the rounding team keeps it.
    final class ScheduledRoundingScore {
        var code: String
        var name: String
        var startsAt: Int
        var unit: String
        var pinned: Bool
        var createdAt: Int
        var description: String
        var maximum: Double
        var status: ScheduledRoundingScoreStatus

        init(code: String, name: String, startsAt: Int, unit: String, pinned: Bool, createdAt: Int, description: String, maximum: Double, status: ScheduledRoundingScoreStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.unit = unit
            self.pinned = pinned
            self.createdAt = createdAt
            self.description = description
            self.maximum = maximum
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

        func canMoveTo(_ next: ScheduledRoundingScoreStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ScheduledRoundingScoreStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledRoundingScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled rounding score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("scheduled rounding score") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(startsAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRoundingScore {
            return ScheduledRoundingScore(
                code: code,
                name: name,
                startsAt: startsAt,
                unit: unit,
                pinned: pinned,
                createdAt: createdAt,
                description: description,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled rounding score in status new.
    static func newScheduledRoundingScore(_ code: String, name: String) -> ScheduledRoundingScore {
        return ScheduledRoundingScore(
            code: code,
            name: name,
            startsAt: 0,
            unit: "",
            pinned: false,
            createdAt: 0,
            description: "",
            maximum: 0.0,
            status: ScheduledRoundingScoreStatus.new
        )
    }
}
