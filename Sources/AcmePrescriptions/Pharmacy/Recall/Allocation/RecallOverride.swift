import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall override is in its life cycle.
    enum RecallOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A recall override as the recall team keeps it.
    final class RecallOverride {
        var code: String
        var name: String
        var timezone: String
        var endsAt: Int
        var visible: Bool
        var status: RecallOverrideStatus

        init(code: String, name: String, timezone: String, endsAt: Int, visible: Bool, status: RecallOverrideStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.endsAt = endsAt
            self.visible = visible
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

        func canMoveTo(_ next: RecallOverrideStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RecallOverrideStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> RecallOverride {
            return RecallOverride(
                code: code,
                name: name,
                timezone: timezone,
                endsAt: endsAt,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall override in status created.
    static func newRecallOverride(_ code: String, name: String) -> RecallOverride {
        return RecallOverride(
            code: code,
            name: name,
            timezone: "",
            endsAt: 0,
            visible: false,
            status: RecallOverrideStatus.created
        )
    }
}
