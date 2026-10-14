import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance profile is in its life cycle.
    enum RemittanceProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A remittance profile as the remittance team keeps it.
    final class RemittanceProfile {
        var code: String
        var name: String
        var updatedAt: Int
        var amount: Double
        var summary: String
        var timezone: String
        var status: RemittanceProfileStatus

        init(code: String, name: String, updatedAt: Int, amount: Double, summary: String, timezone: String, status: RemittanceProfileStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.amount = amount
            self.summary = summary
            self.timezone = timezone
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

        func canMoveTo(_ next: RemittanceProfileStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RemittanceProfileStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RemittanceProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("remittance profile") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(updatedAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> RemittanceProfile {
            return RemittanceProfile(
                code: code,
                name: name,
                updatedAt: updatedAt,
                amount: amount,
                summary: summary,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance profile in status requested.
    static func newRemittanceProfile(_ code: String, name: String) -> RemittanceProfile {
        return RemittanceProfile(
            code: code,
            name: name,
            updatedAt: 0,
            amount: 0.0,
            summary: "",
            timezone: "",
            status: RemittanceProfileStatus.requested
        )
    }
}
