import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession forecast is in its life cycle.
    enum AccessionForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One accession forecast, with what the planners need to act on it.
    final class AccessionForecast {
        var code: String
        var title: String
        var ward: String
        var discount: Double
        var locale: String
        var facility: String
        var createdAt: Int
        var procedureCode: String
        var status: AccessionForecastStatus

        init(code: String, title: String, ward: String, discount: Double, locale: String, facility: String, createdAt: Int, procedureCode: String, status: AccessionForecastStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.discount = discount
            self.locale = locale
            self.facility = facility
            self.createdAt = createdAt
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: AccessionForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AccessionForecastStatus.cancelled
            case .inProgress:
                return next == AccessionForecastStatus.completed || next == AccessionForecastStatus.cancelled
            case .completed:
                return next == AccessionForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("accession forecast") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(createdAt) + discount) * 100).rounded() / 100
        }

        func copyValue() -> AccessionForecast {
            return AccessionForecast(
                code: code,
                title: title,
                ward: ward,
                discount: discount,
                locale: locale,
                facility: facility,
                createdAt: createdAt,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a accession forecast in status planned.
    static func newAccessionForecast(_ code: String, title: String) -> AccessionForecast {
        return AccessionForecast(
            code: code,
            title: title,
            ward: "",
            discount: 0.0,
            locale: "",
            facility: "",
            createdAt: 0,
            procedureCode: "",
            status: AccessionForecastStatus.planned
        )
    }
}
