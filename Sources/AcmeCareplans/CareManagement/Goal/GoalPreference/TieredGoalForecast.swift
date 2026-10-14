import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered goal forecast is in its life cycle.
    enum TieredGoalForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered goal forecast, with what the planners need to act on it.
    final class TieredGoalForecast {
        var code: String
        var name: String
        var facility: String
        var diagnosisCode: String
        var version: Int
        var payer: String
        var status: TieredGoalForecastStatus

        init(code: String, name: String, facility: String, diagnosisCode: String, version: Int, payer: String, status: TieredGoalForecastStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.version = version
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredGoalForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TieredGoalForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredGoalForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered goal forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func copyValue() -> TieredGoalForecast {
            return TieredGoalForecast(
                code: code,
                name: name,
                facility: facility,
                diagnosisCode: diagnosisCode,
                version: version,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a tiered goal forecast in status created.
    static func newTieredGoalForecast(_ code: String, name: String) -> TieredGoalForecast {
        return TieredGoalForecast(
            code: code,
            name: name,
            facility: "",
            diagnosisCode: "",
            version: 0,
            payer: "",
            status: TieredGoalForecastStatus.created
        )
    }
}
