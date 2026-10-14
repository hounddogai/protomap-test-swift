import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual credential window is in its life cycle.
    enum ManualCredentialWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual credential window as the credential team keeps it.
    final class ManualCredentialWindow {
        var code: String
        var name: String
        var category: String
        var batchSize: Int
        var endsAt: Int
        var pinned: Bool
        var status: ManualCredentialWindowStatus

        init(code: String, name: String, category: String, batchSize: Int, endsAt: Int, pinned: Bool, status: ManualCredentialWindowStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.pinned = pinned
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

        func canMoveTo(_ next: ManualCredentialWindowStatus) -> Bool {
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
                return next == ManualCredentialWindowStatus.withdrawn
            case .rejected:
                return next == ManualCredentialWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCredentialWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual credential window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveExposure() -> Double {
            return ((Double(endsAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ManualCredentialWindow {
            return ManualCredentialWindow(
                code: code,
                name: name,
                category: category,
                batchSize: batchSize,
                endsAt: endsAt,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual credential window in status proposed.
    static func newManualCredentialWindow(_ code: String, name: String) -> ManualCredentialWindow {
        return ManualCredentialWindow(
            code: code,
            name: name,
            category: "",
            batchSize: 0,
            endsAt: 0,
            pinned: false,
            status: ManualCredentialWindowStatus.proposed
        )
    }
}
