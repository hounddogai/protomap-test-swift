import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary closure forecast is in its life cycle.
    enum PrimaryClosureForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary closure forecast. Its code is unique within a tenant.
    final class PrimaryClosureForecast {
        var code: String
        var label: String
        var priority: Int
        var phone: String
        var clinicianID: String
        var unit: String
        var minimum: Double
        var status: PrimaryClosureForecastStatus

        init(code: String, label: String, priority: Int, phone: String, clinicianID: String, unit: String, minimum: Double, status: PrimaryClosureForecastStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.phone = phone
            self.clinicianID = clinicianID
            self.unit = unit
            self.minimum = minimum
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

        func canMoveTo(_ next: PrimaryClosureForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryClosureForecastStatus.rejected
            case .approved:
                return next == PrimaryClosureForecastStatus.rejected || next == PrimaryClosureForecastStatus.withdrawn
            case .rejected:
                return next == PrimaryClosureForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryClosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary closure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary closure forecast") \(code)"
        }

        func netValue() -> Double {
            return ((minimum + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryClosureForecast {
            return PrimaryClosureForecast(
                code: code,
                label: label,
                priority: priority,
                phone: phone,
                clinicianID: clinicianID,
                unit: unit,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary closure forecast in status proposed.
    static func newPrimaryClosureForecast(_ code: String, label: String) -> PrimaryClosureForecast {
        return PrimaryClosureForecast(
            code: code,
            label: label,
            priority: 0,
            phone: "",
            clinicianID: "",
            unit: "",
            minimum: 0.0,
            status: PrimaryClosureForecastStatus.proposed
        )
    }
}
