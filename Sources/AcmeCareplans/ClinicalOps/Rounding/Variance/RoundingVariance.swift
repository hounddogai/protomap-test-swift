import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding variance is in its life cycle.
    enum RoundingVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rounding variance. Its code is unique within a tenant.
    final class RoundingVariance {
        var code: String
        var title: String
        var durationMinutes: Int
        var priority: Int
        var facility: String
        var capacity: Int
        var maximum: Double
        var rate: Double
        var startsAt: Int
        var status: RoundingVarianceStatus

        init(code: String, title: String, durationMinutes: Int, priority: Int, facility: String, capacity: Int, maximum: Double, rate: Double, startsAt: Int, status: RoundingVarianceStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.facility = facility
            self.capacity = capacity
            self.maximum = maximum
            self.rate = rate
            self.startsAt = startsAt
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

        func canMoveTo(_ next: RoundingVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RoundingVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rounding variance") \(code)"
        }

        func netExposure() -> Double {
            return (maximum * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> RoundingVariance {
            return RoundingVariance(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                priority: priority,
                facility: facility,
                capacity: capacity,
                maximum: maximum,
                rate: rate,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rounding variance in status proposed.
    static func newRoundingVariance(_ code: String, title: String) -> RoundingVariance {
        return RoundingVariance(
            code: code,
            title: title,
            durationMinutes: 0,
            priority: 0,
            facility: "",
            capacity: 0,
            maximum: 0.0,
            rate: 0.0,
            startsAt: 0,
            status: RoundingVarianceStatus.proposed
        )
    }
}
