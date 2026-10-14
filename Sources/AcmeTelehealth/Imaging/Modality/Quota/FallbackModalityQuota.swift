import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback modality quota is in its life cycle.
    enum FallbackModalityQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback modality quota. Its code is unique within a tenant.
    final class FallbackModalityQuota {
        var code: String
        var name: String
        var timezone: String
        var channel: String
        var copay: Double
        var status: FallbackModalityQuotaStatus

        init(code: String, name: String, timezone: String, channel: String, copay: Double, status: FallbackModalityQuotaStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.channel = channel
            self.copay = copay
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

        func canMoveTo(_ next: FallbackModalityQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FallbackModalityQuotaStatus.rejected || next == FallbackModalityQuotaStatus.withdrawn
            case .rejected:
                return next == FallbackModalityQuotaStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackModalityQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback modality quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> FallbackModalityQuota {
            return FallbackModalityQuota(
                code: code,
                name: name,
                timezone: timezone,
                channel: channel,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback modality quota in status proposed.
    static func newFallbackModalityQuota(_ code: String, name: String) -> FallbackModalityQuota {
        return FallbackModalityQuota(
            code: code,
            name: name,
            timezone: "",
            channel: "",
            copay: 0.0,
            status: FallbackModalityQuotaStatus.proposed
        )
    }
}
