import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal skill mix forecast is in its life cycle.
    enum SeasonalSkillMixForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal skill mix forecast. Its code is unique within a tenant.
    final class SeasonalSkillMixForecast {
        var code: String
        var name: String
        var dosageMg: Double
        var reviewer: String
        var procedureCode: String
        var status: SeasonalSkillMixForecastStatus

        init(code: String, name: String, dosageMg: Double, reviewer: String, procedureCode: String, status: SeasonalSkillMixForecastStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: SeasonalSkillMixForecastStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalSkillMixForecastStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalSkillMixForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal skill mix forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> SeasonalSkillMixForecast {
            return SeasonalSkillMixForecast(
                code: code,
                name: name,
                dosageMg: dosageMg,
                reviewer: reviewer,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal skill mix forecast in status created.
    static func newSeasonalSkillMixForecast(_ code: String, name: String) -> SeasonalSkillMixForecast {
        return SeasonalSkillMixForecast(
            code: code,
            name: name,
            dosageMg: 0.0,
            reviewer: "",
            procedureCode: "",
            status: SeasonalSkillMixForecastStatus.created
        )
    }
}
