import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot exception is in its life cycle.
    enum SlotExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One slot exception, with what the planners need to act on it.
    final class SlotException {
        var code: String
        var title: String
        var label: String
        var timezone: String
        var version: Int
        var endsAt: Int
        var country: String
        var status: SlotExceptionStatus

        init(code: String, title: String, label: String, timezone: String, version: Int, endsAt: Int, country: String, status: SlotExceptionStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.timezone = timezone
            self.version = version
            self.endsAt = endsAt
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == SlotExceptionStatus.ready || next == SlotExceptionStatus.stopped
            case .warming:
                return next == SlotExceptionStatus.draining || next == SlotExceptionStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SlotExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("slot exception") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(endsAt) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SlotException {
            return SlotException(
                code: code,
                title: title,
                label: label,
                timezone: timezone,
                version: version,
                endsAt: endsAt,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a slot exception in status idle.
    static func newSlotException(_ code: String, title: String) -> SlotException {
        return SlotException(
            code: code,
            title: title,
            label: "",
            timezone: "",
            version: 0,
            endsAt: 0,
            country: "",
            status: SlotExceptionStatus.idle
        )
    }
}
