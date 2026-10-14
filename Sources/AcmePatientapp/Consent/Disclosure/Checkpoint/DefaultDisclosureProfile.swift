import AcmePlatform
import Foundation

extension Consent {
    /// Where a default disclosure profile is in its life cycle.
    enum DefaultDisclosureProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a default disclosure profile and its current status.
    final class DefaultDisclosureProfile {
        var code: String
        var label: String
        var updatedAt: Int
        var channel: String
        var title: String
        var status: DefaultDisclosureProfileStatus

        init(code: String, label: String, updatedAt: Int, channel: String, title: String, status: DefaultDisclosureProfileStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.channel = channel
            self.title = title
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

        func canMoveTo(_ next: DefaultDisclosureProfileStatus) -> Bool {
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
                return next == DefaultDisclosureProfileStatus.revoked
            case .revoked:
                return next == DefaultDisclosureProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultDisclosureProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default disclosure profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("default disclosure profile") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> DefaultDisclosureProfile {
            return DefaultDisclosureProfile(
                code: code,
                label: label,
                updatedAt: updatedAt,
                channel: channel,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default disclosure profile in status requested.
    static func newDefaultDisclosureProfile(_ code: String, label: String) -> DefaultDisclosureProfile {
        return DefaultDisclosureProfile(
            code: code,
            label: label,
            updatedAt: 0,
            channel: "",
            title: "",
            status: DefaultDisclosureProfileStatus.requested
        )
    }
}
