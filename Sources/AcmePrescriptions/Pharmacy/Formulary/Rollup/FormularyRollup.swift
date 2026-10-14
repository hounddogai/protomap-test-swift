import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary rollup is in its life cycle.
    enum FormularyRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A formulary rollup. Its code is unique within a tenant.
    final class FormularyRollup {
        var code: String
        var title: String
        var patientRef: String
        var priority: Int
        var graceDays: Int
        var procedureCode: String
        var expiresAt: Int
        var segment: String
        var label: String
        var updatedAt: Int
        var unit: String
        var status: FormularyRollupStatus

        init(code: String, title: String, patientRef: String, priority: Int, graceDays: Int, procedureCode: String, expiresAt: Int, segment: String, label: String, updatedAt: Int, unit: String, status: FormularyRollupStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.priority = priority
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.expiresAt = expiresAt
            self.segment = segment
            self.label = label
            self.updatedAt = updatedAt
            self.unit = unit
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

        func canMoveTo(_ next: FormularyRollupStatus) -> Bool {
            switch status {
            case .created:
                return next == FormularyRollupStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FormularyRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return (Double(graceDays) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> FormularyRollup {
            return FormularyRollup(
                code: code,
                title: title,
                patientRef: patientRef,
                priority: priority,
                graceDays: graceDays,
                procedureCode: procedureCode,
                expiresAt: expiresAt,
                segment: segment,
                label: label,
                updatedAt: updatedAt,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a formulary rollup in status created.
    static func newFormularyRollup(_ code: String, title: String) -> FormularyRollup {
        return FormularyRollup(
            code: code,
            title: title,
            patientRef: "",
            priority: 0,
            graceDays: 0,
            procedureCode: "",
            expiresAt: 0,
            segment: "",
            label: "",
            updatedAt: 0,
            unit: "",
            status: FormularyRollupStatus.created
        )
    }
}
