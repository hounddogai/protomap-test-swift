import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool audit is in its life cycle.
    enum FloatPoolAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A float pool audit as the float pool team keeps it.
    final class FloatPoolAudit {
        var code: String
        var title: String
        var unit: String
        var cost: Double
        var active: Bool
        var copay: Double
        var patientRef: String
        var label: String
        var revision: Int
        var durationMinutes: Int
        var status: FloatPoolAuditStatus

        init(code: String, title: String, unit: String, cost: Double, active: Bool, copay: Double, patientRef: String, label: String, revision: Int, durationMinutes: Int, status: FloatPoolAuditStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.cost = cost
            self.active = active
            self.copay = copay
            self.patientRef = patientRef
            self.label = label
            self.revision = revision
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: FloatPoolAuditStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FloatPoolAuditStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FloatPoolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("float pool audit") \(code)"
        }

        func projectedTotal() -> Double {
            return ((cost - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolAudit {
            return FloatPoolAudit(
                code: code,
                title: title,
                unit: unit,
                cost: cost,
                active: active,
                copay: copay,
                patientRef: patientRef,
                label: label,
                revision: revision,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a float pool audit in status draft.
    static func newFloatPoolAudit(_ code: String, title: String) -> FloatPoolAudit {
        return FloatPoolAudit(
            code: code,
            title: title,
            unit: "",
            cost: 0.0,
            active: false,
            copay: 0.0,
            patientRef: "",
            label: "",
            revision: 0,
            durationMinutes: 0,
            status: FloatPoolAuditStatus.draft
        )
    }
}
