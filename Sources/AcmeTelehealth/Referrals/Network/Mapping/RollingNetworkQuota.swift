import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling network quota is in its life cycle.
    enum RollingNetworkQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One rolling network quota, with what the planners need to act on it.
    final class RollingNetworkQuota {
        var code: String
        var label: String
        var quantity: Int
        var segment: String
        var durationMinutes: Int
        var allergy: String
        var acuity: Int
        var channel: String
        var status: RollingNetworkQuotaStatus

        init(code: String, label: String, quantity: Int, segment: String, durationMinutes: Int, allergy: String, acuity: Int, channel: String, status: RollingNetworkQuotaStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.acuity = acuity
            self.channel = channel
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

        func canMoveTo(_ next: RollingNetworkQuotaStatus) -> Bool {
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
                return next == RollingNetworkQuotaStatus.revoked || next == RollingNetworkQuotaStatus.expired
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

        func moveTo(_ next: RollingNetworkQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling network quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return ((Double(quantity) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingNetworkQuota {
            return RollingNetworkQuota(
                code: code,
                label: label,
                quantity: quantity,
                segment: segment,
                durationMinutes: durationMinutes,
                allergy: allergy,
                acuity: acuity,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling network quota in status requested.
    static func newRollingNetworkQuota(_ code: String, label: String) -> RollingNetworkQuota {
        return RollingNetworkQuota(
            code: code,
            label: label,
            quantity: 0,
            segment: "",
            durationMinutes: 0,
            allergy: "",
            acuity: 0,
            channel: "",
            status: RollingNetworkQuotaStatus.requested
        )
    }
}
