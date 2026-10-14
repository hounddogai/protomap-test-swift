import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan exception is in its life cycle.
    enum AcuityPlanExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One acuity plan exception, with what the planners need to act on it.
    final class AcuityPlanException {
        var code: String
        var name: String
        var maximum: Double
        var region: String
        var capacity: Int
        var updatedAt: Int
        var status: AcuityPlanExceptionStatus

        init(code: String, name: String, maximum: Double, region: String, capacity: Int, updatedAt: Int, status: AcuityPlanExceptionStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.region = region
            self.capacity = capacity
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: AcuityPlanExceptionStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AcuityPlanExceptionStatus.completed || next == AcuityPlanExceptionStatus.cancelled
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

        func moveTo(_ next: AcuityPlanExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return ((Double(updatedAt) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanException {
            return AcuityPlanException(
                code: code,
                name: name,
                maximum: maximum,
                region: region,
                capacity: capacity,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a acuity plan exception in status planned.
    static func newAcuityPlanException(_ code: String, name: String) -> AcuityPlanException {
        return AcuityPlanException(
            code: code,
            name: name,
            maximum: 0.0,
            region: "",
            capacity: 0,
            updatedAt: 0,
            status: AcuityPlanExceptionStatus.planned
        )
    }
}
