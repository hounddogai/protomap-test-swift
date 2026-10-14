import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped slot forecast is in its life cycle.
    enum CappedSlotForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped slot forecast as the slot team keeps it.
    final class CappedSlotForecast {
        var code: String
        var name: String
        var timezone: String
        var score: Double
        var notes: String
        var maximum: Double
        var amount: Double
        var archived: Bool
        var reviewer: String
        var status: CappedSlotForecastStatus

        init(code: String, name: String, timezone: String, score: Double, notes: String, maximum: Double, amount: Double, archived: Bool, reviewer: String, status: CappedSlotForecastStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.score = score
            self.notes = notes
            self.maximum = maximum
            self.amount = amount
            self.archived = archived
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedSlotForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedSlotForecastStatus.withdrawn
            case .rejected:
                return next == CappedSlotForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedSlotForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped slot forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return ((amount + score) * 100).rounded() / 100
        }

        func copyValue() -> CappedSlotForecast {
            return CappedSlotForecast(
                code: code,
                name: name,
                timezone: timezone,
                score: score,
                notes: notes,
                maximum: maximum,
                amount: amount,
                archived: archived,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped slot forecast in status proposed.
    static func newCappedSlotForecast(_ code: String, name: String) -> CappedSlotForecast {
        return CappedSlotForecast(
            code: code,
            name: name,
            timezone: "",
            score: 0.0,
            notes: "",
            maximum: 0.0,
            amount: 0.0,
            archived: false,
            reviewer: "",
            status: CappedSlotForecastStatus.proposed
        )
    }
}
