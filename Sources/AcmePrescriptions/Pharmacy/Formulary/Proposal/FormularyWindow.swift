import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary window is in its life cycle.
    enum FormularyWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A formulary window. Its code is unique within a tenant.
    final class FormularyWindow {
        var code: String
        var name: String
        var channel: String
        var ownerID: String
        var threshold: Double
        var status: FormularyWindowStatus

        init(code: String, name: String, channel: String, ownerID: String, threshold: Double, status: FormularyWindowStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.ownerID = ownerID
            self.threshold = threshold
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

        func canMoveTo(_ next: FormularyWindowStatus) -> Bool {
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
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FormularyWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> FormularyWindow {
            return FormularyWindow(
                code: code,
                name: name,
                channel: channel,
                ownerID: ownerID,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a formulary window in status requested.
    static func newFormularyWindow(_ code: String, name: String) -> FormularyWindow {
        return FormularyWindow(
            code: code,
            name: name,
            channel: "",
            ownerID: "",
            threshold: 0.0,
            status: FormularyWindowStatus.requested
        )
    }
}
