import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling proxy override is in its life cycle.
    enum RollingProxyOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A rolling proxy override as the proxy team keeps it.
    final class RollingProxyOverride {
        var code: String
        var name: String
        var acuity: Int
        var graceDays: Int
        var visitMinutes: Int
        var expiresAt: Int
        var rate: Double
        var summary: String
        var dosageMg: Double
        var ceiling: Double
        var limit: Int
        var status: RollingProxyOverrideStatus

        init(code: String, name: String, acuity: Int, graceDays: Int, visitMinutes: Int, expiresAt: Int, rate: Double, summary: String, dosageMg: Double, ceiling: Double, limit: Int, status: RollingProxyOverrideStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.expiresAt = expiresAt
            self.rate = rate
            self.summary = summary
            self.dosageMg = dosageMg
            self.ceiling = ceiling
            self.limit = limit
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

        func canMoveTo(_ next: RollingProxyOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == RollingProxyOverrideStatus.expired
            case .granted:
                return next == RollingProxyOverrideStatus.expired
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

        func moveTo(_ next: RollingProxyOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling proxy override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling proxy override") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(graceDays) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RollingProxyOverride {
            return RollingProxyOverride(
                code: code,
                name: name,
                acuity: acuity,
                graceDays: graceDays,
                visitMinutes: visitMinutes,
                expiresAt: expiresAt,
                rate: rate,
                summary: summary,
                dosageMg: dosageMg,
                ceiling: ceiling,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling proxy override in status requested.
    static func newRollingProxyOverride(_ code: String, name: String) -> RollingProxyOverride {
        return RollingProxyOverride(
            code: code,
            name: name,
            acuity: 0,
            graceDays: 0,
            visitMinutes: 0,
            expiresAt: 0,
            rate: 0.0,
            summary: "",
            dosageMg: 0.0,
            ceiling: 0.0,
            limit: 0,
            status: RollingProxyOverrideStatus.requested
        )
    }
}
