import AcmePlatform
import Foundation

extension Consent {
    /// Where a default proxy score is in its life cycle.
    enum DefaultProxyScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default proxy score. Its code is unique within a tenant.
    final class DefaultProxyScore {
        var code: String
        var label: String
        var approved: Bool
        var contactEmail: String
        var floorValue: Double
        var durationMinutes: Int
        var expiresAt: Int
        var amount: Double
        var rate: Double
        var status: DefaultProxyScoreStatus

        init(code: String, label: String, approved: Bool, contactEmail: String, floorValue: Double, durationMinutes: Int, expiresAt: Int, amount: Double, rate: Double, status: DefaultProxyScoreStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.amount = amount
            self.rate = rate
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

        func canMoveTo(_ next: DefaultProxyScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultProxyScoreStatus.revoked
            case .granted:
                return next == DefaultProxyScoreStatus.expired
            case .revoked:
                return next == DefaultProxyScoreStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultProxyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default proxy score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return ((rate + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultProxyScore {
            return DefaultProxyScore(
                code: code,
                label: label,
                approved: approved,
                contactEmail: contactEmail,
                floorValue: floorValue,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                amount: amount,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default proxy score in status requested.
    static func newDefaultProxyScore(_ code: String, label: String) -> DefaultProxyScore {
        return DefaultProxyScore(
            code: code,
            label: label,
            approved: false,
            contactEmail: "",
            floorValue: 0.0,
            durationMinutes: 0,
            expiresAt: 0,
            amount: 0.0,
            rate: 0.0,
            status: DefaultProxyScoreStatus.requested
        )
    }
}
