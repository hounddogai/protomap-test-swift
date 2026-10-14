import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional interaction forecast is in its life cycle.
    enum RegionalInteractionForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional interaction forecast. Its code is unique within a tenant.
    final class RegionalInteractionForecast {
        var code: String
        var name: String
        var durationMinutes: Int
        var acuity: Int
        var expiresAt: Int
        var status: RegionalInteractionForecastStatus

        init(code: String, name: String, durationMinutes: Int, acuity: Int, expiresAt: Int, status: RegionalInteractionForecastStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.acuity = acuity
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RegionalInteractionForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalInteractionForecastStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RegionalInteractionForecastStatus.cancelled
            case .completed:
                return next == RegionalInteractionForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalInteractionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional interaction forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional interaction forecast") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(expiresAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalInteractionForecast {
            return RegionalInteractionForecast(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                acuity: acuity,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional interaction forecast in status planned.
    static func newRegionalInteractionForecast(_ code: String, name: String) -> RegionalInteractionForecast {
        return RegionalInteractionForecast(
            code: code,
            name: name,
            durationMinutes: 0,
            acuity: 0,
            expiresAt: 0,
            status: RegionalInteractionForecastStatus.planned
        )
    }
}
