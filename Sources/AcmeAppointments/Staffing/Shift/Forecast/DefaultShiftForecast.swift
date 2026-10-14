import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default shift forecast is in its life cycle.
    enum DefaultShiftForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One default shift forecast, with what the planners need to act on it.
    final class DefaultShiftForecast {
        var code: String
        var name: String
        var batchSize: Int
        var ward: String
        var segment: String
        var status: DefaultShiftForecastStatus

        init(code: String, name: String, batchSize: Int, ward: String, segment: String, status: DefaultShiftForecastStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.ward = ward
            self.segment = segment
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

        func canMoveTo(_ next: DefaultShiftForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultShiftForecastStatus.scheduled || next == DefaultShiftForecastStatus.completed
            case .scheduled:
                return next == DefaultShiftForecastStatus.inProgress || next == DefaultShiftForecastStatus.cancelled
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

        func moveTo(_ next: DefaultShiftForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default shift forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> DefaultShiftForecast {
            return DefaultShiftForecast(
                code: code,
                name: name,
                batchSize: batchSize,
                ward: ward,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default shift forecast in status planned.
    static func newDefaultShiftForecast(_ code: String, name: String) -> DefaultShiftForecast {
        return DefaultShiftForecast(
            code: code,
            name: name,
            batchSize: 0,
            ward: "",
            segment: "",
            status: DefaultShiftForecastStatus.planned
        )
    }
}
