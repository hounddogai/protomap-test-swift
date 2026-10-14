import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional alert forecast is in its life cycle.
    enum RegionalAlertForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional alert forecast and its current status.
    final class RegionalAlertForecast {
        var code: String
        var name: String
        var procedureCode: String
        var country: String
        var cost: Double
        var status: RegionalAlertForecastStatus

        init(code: String, name: String, procedureCode: String, country: String, cost: Double, status: RegionalAlertForecastStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.country = country
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalAlertForecastStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RegionalAlertForecastStatus.ready || next == RegionalAlertForecastStatus.draining
            case .ready:
                return next == RegionalAlertForecastStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalAlertForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional alert forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional alert forecast") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> RegionalAlertForecast {
            return RegionalAlertForecast(
                code: code,
                name: name,
                procedureCode: procedureCode,
                country: country,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional alert forecast in status idle.
    static func newRegionalAlertForecast(_ code: String, name: String) -> RegionalAlertForecast {
        return RegionalAlertForecast(
            code: code,
            name: name,
            procedureCode: "",
            country: "",
            cost: 0.0,
            status: RegionalAlertForecastStatus.idle
        )
    }
}
