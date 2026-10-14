import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal care protocol baseline is in its life cycle.
    enum SeasonalCareProtocolBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal care protocol baseline as the care protocol team keeps it.
    final class SeasonalCareProtocolBaseline {
        var code: String
        var name: String
        var procedureCode: String
        var minimum: Double
        var version: Int
        var patientRef: String
        var currency: String
        var status: SeasonalCareProtocolBaselineStatus

        init(code: String, name: String, procedureCode: String, minimum: Double, version: Int, patientRef: String, currency: String, status: SeasonalCareProtocolBaselineStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.version = version
            self.patientRef = patientRef
            self.currency = currency
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

        func canMoveTo(_ next: SeasonalCareProtocolBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == SeasonalCareProtocolBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCareProtocolBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care protocol baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("seasonal care protocol baseline") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(version) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCareProtocolBaseline {
            return SeasonalCareProtocolBaseline(
                code: code,
                name: name,
                procedureCode: procedureCode,
                minimum: minimum,
                version: version,
                patientRef: patientRef,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal care protocol baseline in status created.
    static func newSeasonalCareProtocolBaseline(_ code: String, name: String) -> SeasonalCareProtocolBaseline {
        return SeasonalCareProtocolBaseline(
            code: code,
            name: name,
            procedureCode: "",
            minimum: 0.0,
            version: 0,
            patientRef: "",
            currency: "",
            status: SeasonalCareProtocolBaselineStatus.created
        )
    }
}
