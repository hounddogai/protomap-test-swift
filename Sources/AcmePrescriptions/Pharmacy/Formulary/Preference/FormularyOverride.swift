import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary override is in its life cycle.
    enum FormularyOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A formulary override as the formulary team keeps it.
    final class FormularyOverride {
        var code: String
        var label: String
        var rate: Double
        var pinned: Bool
        var source: String
        var status: FormularyOverrideStatus

        init(code: String, label: String, rate: Double, pinned: Bool, source: String, status: FormularyOverrideStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.pinned = pinned
            self.source = source
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

        func canMoveTo(_ next: FormularyOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == FormularyOverrideStatus.rejected || next == FormularyOverrideStatus.withdrawn
            case .rejected:
                return next == FormularyOverrideStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> FormularyOverride {
            return FormularyOverride(
                code: code,
                label: label,
                rate: rate,
                pinned: pinned,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a formulary override in status proposed.
    static func newFormularyOverride(_ code: String, label: String) -> FormularyOverride {
        return FormularyOverride(
            code: code,
            label: label,
            rate: 0.0,
            pinned: false,
            source: "",
            status: FormularyOverrideStatus.proposed
        )
    }
}
