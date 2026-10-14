import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap forecast is in its life cycle.
    enum CareGapForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care gap forecast as the care gap team keeps it.
    final class CareGapForecast {
        var code: String
        var name: String
        var summary: String
        var windowDays: Int
        var payer: String
        var floorValue: Double
        var status: CareGapForecastStatus

        init(code: String, name: String, summary: String, windowDays: Int, payer: String, floorValue: Double, status: CareGapForecastStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.windowDays = windowDays
            self.payer = payer
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CareGapForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == CareGapForecastStatus.scheduled || next == CareGapForecastStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CareGapForecastStatus.completed || next == CareGapForecastStatus.cancelled
            case .completed:
                return next == CareGapForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return (Double(windowDays) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CareGapForecast {
            return CareGapForecast(
                code: code,
                name: name,
                summary: summary,
                windowDays: windowDays,
                payer: payer,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care gap forecast in status planned.
    static func newCareGapForecast(_ code: String, name: String) -> CareGapForecast {
        return CareGapForecast(
            code: code,
            name: name,
            summary: "",
            windowDays: 0,
            payer: "",
            floorValue: 0.0,
            status: CareGapForecastStatus.planned
        )
    }
}
