import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy interaction forecast is in its life cycle.
    enum LegacyInteractionForecastStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy interaction forecast as the interaction team keeps it.
    final class LegacyInteractionForecast {
        var code: String
        var title: String
        var ward: String
        var facility: String
        var dosageMg: Double
        var externalRef: String
        var clinicianID: String
        var segment: String
        var budget: Double
        var summary: String
        var status: LegacyInteractionForecastStatus

        init(code: String, title: String, ward: String, facility: String, dosageMg: Double, externalRef: String, clinicianID: String, segment: String, budget: Double, summary: String, status: LegacyInteractionForecastStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.facility = facility
            self.dosageMg = dosageMg
            self.externalRef = externalRef
            self.clinicianID = clinicianID
            self.segment = segment
            self.budget = budget
            self.summary = summary
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

        func canMoveTo(_ next: LegacyInteractionForecastStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LegacyInteractionForecastStatus.cancelled
            case .inProgress:
                return next == LegacyInteractionForecastStatus.completed
            case .completed:
                return next == LegacyInteractionForecastStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyInteractionForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy interaction forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedLoad() -> Double {
            return ((budget + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LegacyInteractionForecast {
            return LegacyInteractionForecast(
                code: code,
                title: title,
                ward: ward,
                facility: facility,
                dosageMg: dosageMg,
                externalRef: externalRef,
                clinicianID: clinicianID,
                segment: segment,
                budget: budget,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy interaction forecast in status planned.
    static func newLegacyInteractionForecast(_ code: String, title: String) -> LegacyInteractionForecast {
        return LegacyInteractionForecast(
            code: code,
            title: title,
            ward: "",
            facility: "",
            dosageMg: 0.0,
            externalRef: "",
            clinicianID: "",
            segment: "",
            budget: 0.0,
            summary: "",
            status: LegacyInteractionForecastStatus.planned
        )
    }
}
