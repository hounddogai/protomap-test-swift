import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation forecast is in its life cycle.
    enum IsolationForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A isolation forecast as the isolation team keeps it.
    final class IsolationForecast {
        var code: String
        var name: String
        var version: Int
        var country: String
        var region: String
        var status: IsolationForecastStatus

        init(code: String, name: String, version: Int, country: String, region: String, status: IsolationForecastStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.country = country
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == IsolationForecastStatus.inReview || next == IsolationForecastStatus.reopened
            case .inReview:
                return next == IsolationForecastStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == IsolationForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> IsolationForecast {
            return IsolationForecast(
                code: code,
                name: name,
                version: version,
                country: country,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a isolation forecast in status open.
    static func newIsolationForecast(_ code: String, name: String) -> IsolationForecast {
        return IsolationForecast(
            code: code,
            name: name,
            version: 0,
            country: "",
            region: "",
            status: IsolationForecastStatus.`open`
        )
    }
}
