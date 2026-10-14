import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study forecast is in its life cycle.
    enum StudyForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One study forecast, with what the planners need to act on it.
    final class StudyForecast {
        var code: String
        var label: String
        var unit: String
        var timezone: String
        var refills: Int
        var procedureCode: String
        var copay: Double
        var checksum: String
        var status: StudyForecastStatus

        init(code: String, label: String, unit: String, timezone: String, refills: Int, procedureCode: String, copay: Double, checksum: String, status: StudyForecastStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.timezone = timezone
            self.refills = refills
            self.procedureCode = procedureCode
            self.copay = copay
            self.checksum = checksum
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

        func canMoveTo(_ next: StudyForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StudyForecastStatus.approved || next == StudyForecastStatus.withdrawn
            case .approved:
                return next == StudyForecastStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StudyForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("study forecast") \(code)"
        }

        func effectiveValue() -> Double {
            return ((Double(refills) + copay) * 100).rounded() / 100
        }

        func copyValue() -> StudyForecast {
            return StudyForecast(
                code: code,
                label: label,
                unit: unit,
                timezone: timezone,
                refills: refills,
                procedureCode: procedureCode,
                copay: copay,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a study forecast in status proposed.
    static func newStudyForecast(_ code: String, label: String) -> StudyForecast {
        return StudyForecast(
            code: code,
            label: label,
            unit: "",
            timezone: "",
            refills: 0,
            procedureCode: "",
            copay: 0.0,
            checksum: "",
            status: StudyForecastStatus.proposed
        )
    }
}
