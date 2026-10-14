import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary profile is in its life cycle.
    enum FormularyProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a formulary profile and its current status.
    final class FormularyProfile {
        var code: String
        var label: String
        var version: Int
        var name: String
        var minimum: Double
        var status: FormularyProfileStatus

        init(code: String, label: String, version: Int, name: String, minimum: Double, status: FormularyProfileStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.name = name
            self.minimum = minimum
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

        func canMoveTo(_ next: FormularyProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == FormularyProfileStatus.pending
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FormularyProfileStatus.closed
            case .suspended:
                return next == FormularyProfileStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (minimum * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> FormularyProfile {
            return FormularyProfile(
                code: code,
                label: label,
                version: version,
                name: name,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a formulary profile in status draft.
    static func newFormularyProfile(_ code: String, label: String) -> FormularyProfile {
        return FormularyProfile(
            code: code,
            label: label,
            version: 0,
            name: "",
            minimum: 0.0,
            status: FormularyProfileStatus.draft
        )
    }
}
