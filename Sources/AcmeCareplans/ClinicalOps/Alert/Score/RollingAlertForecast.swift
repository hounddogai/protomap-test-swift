import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling alert forecast is in its life cycle.
    enum RollingAlertForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling alert forecast as the alert team keeps it.
    final class RollingAlertForecast {
        var code: String
        var label: String
        var expiresAt: Int
        var reviewer: String
        var currency: String
        var floorValue: Double
        var encounterID: String
        var attempts: Int
        var status: RollingAlertForecastStatus

        init(code: String, label: String, expiresAt: Int, reviewer: String, currency: String, floorValue: Double, encounterID: String, attempts: Int, status: RollingAlertForecastStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.reviewer = reviewer
            self.currency = currency
            self.floorValue = floorValue
            self.encounterID = encounterID
            self.attempts = attempts
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

        func canMoveTo(_ next: RollingAlertForecastStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingAlertForecastStatus.active || next == RollingAlertForecastStatus.closed
            case .pending:
                return next == RollingAlertForecastStatus.suspended || next == RollingAlertForecastStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RollingAlertForecastStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAlertForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling alert forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((floorValue - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingAlertForecast {
            return RollingAlertForecast(
                code: code,
                label: label,
                expiresAt: expiresAt,
                reviewer: reviewer,
                currency: currency,
                floorValue: floorValue,
                encounterID: encounterID,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling alert forecast in status draft.
    static func newRollingAlertForecast(_ code: String, label: String) -> RollingAlertForecast {
        return RollingAlertForecast(
            code: code,
            label: label,
            expiresAt: 0,
            reviewer: "",
            currency: "",
            floorValue: 0.0,
            encounterID: "",
            attempts: 0,
            status: RollingAlertForecastStatus.draft
        )
    }
}
