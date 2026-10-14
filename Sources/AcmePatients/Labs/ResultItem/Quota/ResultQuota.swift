import AcmePlatform
import Foundation

extension Labs {
    /// Where a result quota is in its life cycle.
    enum ResultQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result quota. Its code is unique within a tenant.
    final class ResultQuota {
        var code: String
        var label: String
        var endsAt: Int
        var cost: Double
        var version: Int
        var channel: String
        var segment: String
        var status: ResultQuotaStatus

        init(code: String, label: String, endsAt: Int, cost: Double, version: Int, channel: String, segment: String, status: ResultQuotaStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.cost = cost
            self.version = version
            self.channel = channel
            self.segment = segment
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

        func canMoveTo(_ next: ResultQuotaStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ResultQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedTotal() -> Double {
            return ((Double(version) - cost) * 100).rounded() / 100
        }

        func copyValue() -> ResultQuota {
            return ResultQuota(
                code: code,
                label: label,
                endsAt: endsAt,
                cost: cost,
                version: version,
                channel: channel,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result quota in status requested.
    static func newResultQuota(_ code: String, label: String) -> ResultQuota {
        return ResultQuota(
            code: code,
            label: label,
            endsAt: 0,
            cost: 0.0,
            version: 0,
            channel: "",
            segment: "",
            status: ResultQuotaStatus.requested
        )
    }
}
