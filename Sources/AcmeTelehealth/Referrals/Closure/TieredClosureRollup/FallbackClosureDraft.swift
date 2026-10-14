import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback closure draft is in its life cycle.
    enum FallbackClosureDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback closure draft, with what the planners need to act on it.
    final class FallbackClosureDraft {
        var code: String
        var label: String
        var timezone: String
        var reviewer: String
        var amount: Double
        var channel: String
        var endsAt: Int
        var active: Bool
        var retries: Int
        var status: FallbackClosureDraftStatus

        init(code: String, label: String, timezone: String, reviewer: String, amount: Double, channel: String, endsAt: Int, active: Bool, retries: Int, status: FallbackClosureDraftStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.reviewer = reviewer
            self.amount = amount
            self.channel = channel
            self.endsAt = endsAt
            self.active = active
            self.retries = retries
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

        func canMoveTo(_ next: FallbackClosureDraftStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == FallbackClosureDraftStatus.expired
            case .revoked:
                return next == FallbackClosureDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackClosureDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback closure draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return (amount * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> FallbackClosureDraft {
            return FallbackClosureDraft(
                code: code,
                label: label,
                timezone: timezone,
                reviewer: reviewer,
                amount: amount,
                channel: channel,
                endsAt: endsAt,
                active: active,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback closure draft in status requested.
    static func newFallbackClosureDraft(_ code: String, label: String) -> FallbackClosureDraft {
        return FallbackClosureDraft(
            code: code,
            label: label,
            timezone: "",
            reviewer: "",
            amount: 0.0,
            channel: "",
            endsAt: 0,
            active: false,
            retries: 0,
            status: FallbackClosureDraftStatus.requested
        )
    }
}
