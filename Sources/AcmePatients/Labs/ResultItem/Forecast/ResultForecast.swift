import AcmePlatform
import Foundation

extension Labs {
    /// Where a result forecast is in its life cycle.
    enum ResultForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One result forecast, with what the planners need to act on it.
    final class ResultForecast {
        var code: String
        var label: String
        var title: String
        var locale: String
        var weight: Double
        var floorValue: Double
        var discount: Double
        var status: ResultForecastStatus

        init(code: String, label: String, title: String, locale: String, weight: Double, floorValue: Double, discount: Double, status: ResultForecastStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.locale = locale
            self.weight = weight
            self.floorValue = floorValue
            self.discount = discount
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

        func canMoveTo(_ next: ResultForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ResultForecastStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ResultForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveVolume() -> Double {
            return (weight * discount * 100).rounded() / 100
        }

        func copyValue() -> ResultForecast {
            return ResultForecast(
                code: code,
                label: label,
                title: title,
                locale: locale,
                weight: weight,
                floorValue: floorValue,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a result forecast in status planned.
    static func newResultForecast(_ code: String, label: String) -> ResultForecast {
        return ResultForecast(
            code: code,
            label: label,
            title: "",
            locale: "",
            weight: 0.0,
            floorValue: 0.0,
            discount: 0.0,
            status: ResultForecastStatus.planned
        )
    }
}
