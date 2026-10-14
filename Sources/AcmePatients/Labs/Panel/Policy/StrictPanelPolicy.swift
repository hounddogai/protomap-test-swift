import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict panel policy is in its life cycle.
    enum StrictPanelPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A strict panel policy. Its code is unique within a tenant.
    final class StrictPanelPolicy {
        var code: String
        var title: String
        var windowDays: Int
        var payer: String
        var expiresAt: Int
        var channel: String
        var sequence: Int
        var active: Bool
        var status: StrictPanelPolicyStatus

        init(code: String, title: String, windowDays: Int, payer: String, expiresAt: Int, channel: String, sequence: Int, active: Bool, status: StrictPanelPolicyStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.payer = payer
            self.expiresAt = expiresAt
            self.channel = channel
            self.sequence = sequence
            self.active = active
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

        func canMoveTo(_ next: StrictPanelPolicyStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == StrictPanelPolicyStatus.revoked || next == StrictPanelPolicyStatus.expired
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

        func moveTo(_ next: StrictPanelPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict panel policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(sequence) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> StrictPanelPolicy {
            return StrictPanelPolicy(
                code: code,
                title: title,
                windowDays: windowDays,
                payer: payer,
                expiresAt: expiresAt,
                channel: channel,
                sequence: sequence,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict panel policy in status requested.
    static func newStrictPanelPolicy(_ code: String, title: String) -> StrictPanelPolicy {
        return StrictPanelPolicy(
            code: code,
            title: title,
            windowDays: 0,
            payer: "",
            expiresAt: 0,
            channel: "",
            sequence: 0,
            active: false,
            status: StrictPanelPolicyStatus.requested
        )
    }
}
