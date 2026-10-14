import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning forecast is in its life cycle.
    enum CleaningForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A cleaning forecast. Its code is unique within a tenant.
    final class CleaningForecast {
        var code: String
        var name: String
        var windowDays: Int
        var country: String
        var limit: Int
        var ward: String
        var graceDays: Int
        var notes: String
        var status: CleaningForecastStatus

        init(code: String, name: String, windowDays: Int, country: String, limit: Int, ward: String, graceDays: Int, notes: String, status: CleaningForecastStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.country = country
            self.limit = limit
            self.ward = ward
            self.graceDays = graceDays
            self.notes = notes
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

        func canMoveTo(_ next: CleaningForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CleaningForecastStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CleaningForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return (Double(limit) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> CleaningForecast {
            return CleaningForecast(
                code: code,
                name: name,
                windowDays: windowDays,
                country: country,
                limit: limit,
                ward: ward,
                graceDays: graceDays,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a cleaning forecast in status planned.
    static func newCleaningForecast(_ code: String, name: String) -> CleaningForecast {
        return CleaningForecast(
            code: code,
            name: name,
            windowDays: 0,
            country: "",
            limit: 0,
            ward: "",
            graceDays: 0,
            notes: "",
            status: CleaningForecastStatus.planned
        )
    }
}
