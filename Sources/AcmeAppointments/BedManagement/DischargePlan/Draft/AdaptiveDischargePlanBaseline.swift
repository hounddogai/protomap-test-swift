import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive discharge plan baseline is in its life cycle.
    enum AdaptiveDischargePlanBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a adaptive discharge plan baseline and its current status.
    final class AdaptiveDischargePlanBaseline {
        var code: String
        var name: String
        var country: String
        var rate: Double
        var capacity: Int
        var active: Bool
        var status: AdaptiveDischargePlanBaselineStatus

        init(code: String, name: String, country: String, rate: Double, capacity: Int, active: Bool, status: AdaptiveDischargePlanBaselineStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.rate = rate
            self.capacity = capacity
            self.active = active
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

        func canMoveTo(_ next: AdaptiveDischargePlanBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == AdaptiveDischargePlanBaselineStatus.inProgress || next == AdaptiveDischargePlanBaselineStatus.completed
            case .scheduled:
                return next == AdaptiveDischargePlanBaselineStatus.completed
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: AdaptiveDischargePlanBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive discharge plan baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive discharge plan baseline") \(code)"
        }

        func netExposure() -> Double {
            return ((rate - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDischargePlanBaseline {
            return AdaptiveDischargePlanBaseline(
                code: code,
                name: name,
                country: country,
                rate: rate,
                capacity: capacity,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive discharge plan baseline in status planned.
    static func newAdaptiveDischargePlanBaseline(_ code: String, name: String) -> AdaptiveDischargePlanBaseline {
        return AdaptiveDischargePlanBaseline(
            code: code,
            name: name,
            country: "",
            rate: 0.0,
            capacity: 0,
            active: false,
            status: AdaptiveDischargePlanBaselineStatus.planned
        )
    }
}
