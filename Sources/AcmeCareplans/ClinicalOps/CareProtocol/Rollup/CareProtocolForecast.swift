import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol forecast is in its life cycle.
    enum CareProtocolForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One care protocol forecast, with what the planners need to act on it.
    final class CareProtocolForecast {
        var code: String
        var title: String
        var label: String
        var bed: String
        var createdAt: Int
        var facility: String
        var dosageMg: Double
        var status: CareProtocolForecastStatus

        init(code: String, title: String, label: String, bed: String, createdAt: Int, facility: String, dosageMg: Double, status: CareProtocolForecastStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.bed = bed
            self.createdAt = createdAt
            self.facility = facility
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: CareProtocolForecastStatus) -> Bool {
            switch status {
            case .planned:
                return next == CareProtocolForecastStatus.scheduled
            case .scheduled:
                return next == CareProtocolForecastStatus.inProgress || next == CareProtocolForecastStatus.completed
            case .inProgress:
                return next == CareProtocolForecastStatus.completed
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

        func moveTo(_ next: CareProtocolForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("care protocol forecast") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(createdAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolForecast {
            return CareProtocolForecast(
                code: code,
                title: title,
                label: label,
                bed: bed,
                createdAt: createdAt,
                facility: facility,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care protocol forecast in status planned.
    static func newCareProtocolForecast(_ code: String, title: String) -> CareProtocolForecast {
        return CareProtocolForecast(
            code: code,
            title: title,
            label: "",
            bed: "",
            createdAt: 0,
            facility: "",
            dosageMg: 0.0,
            status: CareProtocolForecastStatus.planned
        )
    }
}
