import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default program baseline is in its life cycle.
    enum DefaultProgramBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default program baseline. Its code is unique within a tenant.
    final class DefaultProgramBaseline {
        var code: String
        var label: String
        var graceDays: Int
        var active: Bool
        var visible: Bool
        var status: DefaultProgramBaselineStatus

        init(code: String, label: String, graceDays: Int, active: Bool, visible: Bool, status: DefaultProgramBaselineStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.active = active
            self.visible = visible
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

        func canMoveTo(_ next: DefaultProgramBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultProgramBaselineStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultProgramBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultProgramBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default program baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> DefaultProgramBaseline {
            return DefaultProgramBaseline(
                code: code,
                label: label,
                graceDays: graceDays,
                active: active,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default program baseline in status requested.
    static func newDefaultProgramBaseline(_ code: String, label: String) -> DefaultProgramBaseline {
        return DefaultProgramBaseline(
            code: code,
            label: label,
            graceDays: 0,
            active: false,
            visible: false,
            status: DefaultProgramBaselineStatus.requested
        )
    }
}
