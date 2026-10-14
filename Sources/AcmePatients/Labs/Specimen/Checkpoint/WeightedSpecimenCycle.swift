import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted specimen cycle is in its life cycle.
    enum WeightedSpecimenCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted specimen cycle as the specimen team keeps it.
    final class WeightedSpecimenCycle {
        var code: String
        var name: String
        var ward: String
        var updatedAt: Int
        var threshold: Double
        var rate: Double
        var minimum: Double
        var retries: Int
        var maximum: Double
        var status: WeightedSpecimenCycleStatus

        init(code: String, name: String, ward: String, updatedAt: Int, threshold: Double, rate: Double, minimum: Double, retries: Int, maximum: Double, status: WeightedSpecimenCycleStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.rate = rate
            self.minimum = minimum
            self.retries = retries
            self.maximum = maximum
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

        func canMoveTo(_ next: WeightedSpecimenCycleStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedSpecimenCycleStatus.scheduled || next == WeightedSpecimenCycleStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: WeightedSpecimenCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted specimen cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return (threshold * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedSpecimenCycle {
            return WeightedSpecimenCycle(
                code: code,
                name: name,
                ward: ward,
                updatedAt: updatedAt,
                threshold: threshold,
                rate: rate,
                minimum: minimum,
                retries: retries,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted specimen cycle in status planned.
    static func newWeightedSpecimenCycle(_ code: String, name: String) -> WeightedSpecimenCycle {
        return WeightedSpecimenCycle(
            code: code,
            name: name,
            ward: "",
            updatedAt: 0,
            threshold: 0.0,
            rate: 0.0,
            minimum: 0.0,
            retries: 0,
            maximum: 0.0,
            status: WeightedSpecimenCycleStatus.planned
        )
    }
}
