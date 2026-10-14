import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global handoff manifest is in its life cycle.
    enum GlobalHandoffManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global handoff manifest, with what the planners need to act on it.
    final class GlobalHandoffManifest {
        var code: String
        var label: String
        var patientRef: String
        var notes: String
        var amount: Double
        var status: GlobalHandoffManifestStatus

        init(code: String, label: String, patientRef: String, notes: String, amount: Double, status: GlobalHandoffManifestStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.notes = notes
            self.amount = amount
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

        func canMoveTo(_ next: GlobalHandoffManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalHandoffManifestStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalHandoffManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global handoff manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> GlobalHandoffManifest {
            return GlobalHandoffManifest(
                code: code,
                label: label,
                patientRef: patientRef,
                notes: notes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global handoff manifest in status requested.
    static func newGlobalHandoffManifest(_ code: String, label: String) -> GlobalHandoffManifest {
        return GlobalHandoffManifest(
            code: code,
            label: label,
            patientRef: "",
            notes: "",
            amount: 0.0,
            status: GlobalHandoffManifestStatus.requested
        )
    }
}
