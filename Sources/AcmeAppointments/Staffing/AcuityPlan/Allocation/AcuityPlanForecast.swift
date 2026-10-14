import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan forecast is in its life cycle.
    enum AcuityPlanForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One acuity plan forecast, with what the planners need to act on it.
    final class AcuityPlanForecast {
        var code: String
        var title: String
        var dosageMg: Double
        var ward: String
        var summary: String
        var ratio: Double
        var procedureCode: String
        var priority: Int
        var attributes: [String: String]
        var checksum: String
        var status: AcuityPlanForecastStatus

        init(code: String, title: String, dosageMg: Double, ward: String, summary: String, ratio: Double, procedureCode: String, priority: Int, attributes: [String: String], checksum: String, status: AcuityPlanForecastStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.ward = ward
            self.summary = summary
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.priority = priority
            self.attributes = attributes
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanForecastStatus) -> Bool {
            switch status {
            case .draft:
                return next == AcuityPlanForecastStatus.suspended
            case .pending:
                return next == AcuityPlanForecastStatus.active || next == AcuityPlanForecastStatus.suspended
            case .active:
                return next == AcuityPlanForecastStatus.suspended
            case .suspended:
                return next == AcuityPlanForecastStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netVolume() -> Double {
            return (Double(priority) * ratio * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanForecast {
            return AcuityPlanForecast(
                code: code,
                title: title,
                dosageMg: dosageMg,
                ward: ward,
                summary: summary,
                ratio: ratio,
                procedureCode: procedureCode,
                priority: priority,
                attributes: attributes,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a acuity plan forecast in status draft.
    static func newAcuityPlanForecast(_ code: String, title: String) -> AcuityPlanForecast {
        return AcuityPlanForecast(
            code: code,
            title: title,
            dosageMg: 0.0,
            ward: "",
            summary: "",
            ratio: 0.0,
            procedureCode: "",
            priority: 0,
            attributes: [:],
            checksum: "",
            status: AcuityPlanForecastStatus.draft
        )
    }
}
