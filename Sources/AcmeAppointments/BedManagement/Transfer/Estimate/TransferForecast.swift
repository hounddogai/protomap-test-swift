import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer forecast is in its life cycle.
    enum TransferForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A transfer forecast as the transfer team keeps it.
    final class TransferForecast {
        var code: String
        var name: String
        var weight: Double
        var label: String
        var cost: Double
        var clinicianID: String
        var status: TransferForecastStatus

        init(code: String, name: String, weight: Double, label: String, cost: Double, clinicianID: String, status: TransferForecastStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.label = label
            self.cost = cost
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferForecastStatus) -> Bool {
            switch status {
            case .requested:
                return next == TransferForecastStatus.revoked
            case .granted:
                return next == TransferForecastStatus.revoked || next == TransferForecastStatus.expired
            case .revoked:
                return next == TransferForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("transfer forecast") \(code)"
        }

        func netLoad() -> Double {
            return ((cost - weight) * 100).rounded() / 100
        }

        func copyValue() -> TransferForecast {
            return TransferForecast(
                code: code,
                name: name,
                weight: weight,
                label: label,
                cost: cost,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a transfer forecast in status requested.
    static func newTransferForecast(_ code: String, name: String) -> TransferForecast {
        return TransferForecast(
            code: code,
            name: name,
            weight: 0.0,
            label: "",
            cost: 0.0,
            clinicianID: "",
            status: TransferForecastStatus.requested
        )
    }
}
