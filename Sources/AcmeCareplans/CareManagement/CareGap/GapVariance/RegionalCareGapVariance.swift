import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional care gap variance is in its life cycle.
    enum RegionalCareGapVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional care gap variance, with what the planners need to act on it.
    final class RegionalCareGapVariance {
        var code: String
        var label: String
        var expiresAt: Int
        var currency: String
        var budget: Double
        var minimum: Double
        var channel: String
        var facility: String
        var capacity: Int
        var status: RegionalCareGapVarianceStatus

        init(code: String, label: String, expiresAt: Int, currency: String, budget: Double, minimum: Double, channel: String, facility: String, capacity: Int, status: RegionalCareGapVarianceStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.currency = currency
            self.budget = budget
            self.minimum = minimum
            self.channel = channel
            self.facility = facility
            self.capacity = capacity
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

        func canMoveTo(_ next: RegionalCareGapVarianceStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalCareGapVarianceStatus.granted
            case .granted:
                return next == RegionalCareGapVarianceStatus.revoked
            case .revoked:
                return next == RegionalCareGapVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareGapVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care gap variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedLoad() -> Double {
            return ((budget + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareGapVariance {
            return RegionalCareGapVariance(
                code: code,
                label: label,
                expiresAt: expiresAt,
                currency: currency,
                budget: budget,
                minimum: minimum,
                channel: channel,
                facility: facility,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional care gap variance in status requested.
    static func newRegionalCareGapVariance(_ code: String, label: String) -> RegionalCareGapVariance {
        return RegionalCareGapVariance(
            code: code,
            label: label,
            expiresAt: 0,
            currency: "",
            budget: 0.0,
            minimum: 0.0,
            channel: "",
            facility: "",
            capacity: 0,
            status: RegionalCareGapVarianceStatus.requested
        )
    }
}
