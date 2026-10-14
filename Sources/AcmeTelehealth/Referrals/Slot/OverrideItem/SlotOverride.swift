import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot override is in its life cycle.
    enum SlotOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A slot override as the slot team keeps it.
    final class SlotOverride {
        var code: String
        var title: String
        var visible: Bool
        var copay: Double
        var externalRef: String
        var active: Bool
        var expiresAt: Int
        var status: SlotOverrideStatus

        init(code: String, title: String, visible: Bool, copay: Double, externalRef: String, active: Bool, expiresAt: Int, status: SlotOverrideStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.copay = copay
            self.externalRef = externalRef
            self.active = active
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotOverrideStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SlotOverrideStatus.active || next == SlotOverrideStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == SlotOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return (Double(expiresAt) * copay * 100).rounded() / 100
        }

        func copyValue() -> SlotOverride {
            return SlotOverride(
                code: code,
                title: title,
                visible: visible,
                copay: copay,
                externalRef: externalRef,
                active: active,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot override in status draft.
    static func newSlotOverride(_ code: String, title: String) -> SlotOverride {
        return SlotOverride(
            code: code,
            title: title,
            visible: false,
            copay: 0.0,
            externalRef: "",
            active: false,
            expiresAt: 0,
            status: SlotOverrideStatus.draft
        )
    }
}
