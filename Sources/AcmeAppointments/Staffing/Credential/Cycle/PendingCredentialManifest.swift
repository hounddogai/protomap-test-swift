import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending credential manifest is in its life cycle.
    enum PendingCredentialManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending credential manifest, with what the planners need to act on it.
    final class PendingCredentialManifest {
        var code: String
        var label: String
        var minimum: Double
        var maximum: Double
        var externalRef: String
        var status: PendingCredentialManifestStatus

        init(code: String, label: String, minimum: Double, maximum: Double, externalRef: String, status: PendingCredentialManifestStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.maximum = maximum
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PendingCredentialManifestStatus) -> Bool {
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
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PendingCredentialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending credential manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return ((minimum - maximum) * 100).rounded() / 100
        }

        func copyValue() -> PendingCredentialManifest {
            return PendingCredentialManifest(
                code: code,
                label: label,
                minimum: minimum,
                maximum: maximum,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending credential manifest in status proposed.
    static func newPendingCredentialManifest(_ code: String, label: String) -> PendingCredentialManifest {
        return PendingCredentialManifest(
            code: code,
            label: label,
            minimum: 0.0,
            maximum: 0.0,
            externalRef: "",
            status: PendingCredentialManifestStatus.proposed
        )
    }
}
