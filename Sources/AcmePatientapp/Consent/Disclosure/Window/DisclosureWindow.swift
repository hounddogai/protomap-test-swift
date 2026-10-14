import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure window is in its life cycle.
    enum DisclosureWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A disclosure window. Its code is unique within a tenant.
    final class DisclosureWindow {
        var code: String
        var name: String
        var minimum: Double
        var locale: String
        var ceiling: Double
        var attempts: Int
        var pinned: Bool
        var expiresAt: Int
        var procedureCode: String
        var channel: String
        var status: DisclosureWindowStatus

        init(code: String, name: String, minimum: Double, locale: String, ceiling: Double, attempts: Int, pinned: Bool, expiresAt: Int, procedureCode: String, channel: String, status: DisclosureWindowStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.locale = locale
            self.ceiling = ceiling
            self.attempts = attempts
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.procedureCode = procedureCode
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DisclosureWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == DisclosureWindowStatus.published || next == DisclosureWindowStatus.retired
            case .published:
                return next == DisclosureWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return (minimum * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureWindow {
            return DisclosureWindow(
                code: code,
                name: name,
                minimum: minimum,
                locale: locale,
                ceiling: ceiling,
                attempts: attempts,
                pinned: pinned,
                expiresAt: expiresAt,
                procedureCode: procedureCode,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a disclosure window in status created.
    static func newDisclosureWindow(_ code: String, name: String) -> DisclosureWindow {
        return DisclosureWindow(
            code: code,
            name: name,
            minimum: 0.0,
            locale: "",
            ceiling: 0.0,
            attempts: 0,
            pinned: false,
            expiresAt: 0,
            procedureCode: "",
            channel: "",
            status: DisclosureWindowStatus.created
        )
    }
}
