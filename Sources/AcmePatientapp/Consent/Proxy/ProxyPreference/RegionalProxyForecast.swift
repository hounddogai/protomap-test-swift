import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional proxy forecast is in its life cycle.
    enum RegionalProxyForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a regional proxy forecast and its current status.
    final class RegionalProxyForecast {
        var code: String
        var title: String
        var active: Bool
        var procedureCode: String
        var label: String
        var patientRef: String
        var limit: Int
        var status: RegionalProxyForecastStatus

        init(code: String, title: String, active: Bool, procedureCode: String, label: String, patientRef: String, limit: Int, status: RegionalProxyForecastStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.procedureCode = procedureCode
            self.label = label
            self.patientRef = patientRef
            self.limit = limit
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

        func canMoveTo(_ next: RegionalProxyForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RegionalProxyForecastStatus.rejected || next == RegionalProxyForecastStatus.withdrawn
            case .rejected:
                return next == RegionalProxyForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalProxyForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional proxy forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> RegionalProxyForecast {
            return RegionalProxyForecast(
                code: code,
                title: title,
                active: active,
                procedureCode: procedureCode,
                label: label,
                patientRef: patientRef,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional proxy forecast in status proposed.
    static func newRegionalProxyForecast(_ code: String, title: String) -> RegionalProxyForecast {
        return RegionalProxyForecast(
            code: code,
            title: title,
            active: false,
            procedureCode: "",
            label: "",
            patientRef: "",
            limit: 0,
            status: RegionalProxyForecastStatus.proposed
        )
    }
}
