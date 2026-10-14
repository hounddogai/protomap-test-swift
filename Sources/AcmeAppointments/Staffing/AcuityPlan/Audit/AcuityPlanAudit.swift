import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan audit is in its life cycle.
    enum AcuityPlanAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A acuity plan audit. Its code is unique within a tenant.
    final class AcuityPlanAudit {
        var code: String
        var title: String
        var weight: Double
        var notes: String
        var label: String
        var windowDays: Int
        var maximum: Double
        var procedureCode: String
        var status: AcuityPlanAuditStatus

        init(code: String, title: String, weight: Double, notes: String, label: String, windowDays: Int, maximum: Double, procedureCode: String, status: AcuityPlanAuditStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.notes = notes
            self.label = label
            self.windowDays = windowDays
            self.maximum = maximum
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanAuditStatus) -> Bool {
            switch status {
            case .new:
                return next == AcuityPlanAuditStatus.queued || next == AcuityPlanAuditStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AcuityPlanAuditStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AcuityPlanAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return ((maximum + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanAudit {
            return AcuityPlanAudit(
                code: code,
                title: title,
                weight: weight,
                notes: notes,
                label: label,
                windowDays: windowDays,
                maximum: maximum,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a acuity plan audit in status new.
    static func newAcuityPlanAudit(_ code: String, title: String) -> AcuityPlanAudit {
        return AcuityPlanAudit(
            code: code,
            title: title,
            weight: 0.0,
            notes: "",
            label: "",
            windowDays: 0,
            maximum: 0.0,
            procedureCode: "",
            status: AcuityPlanAuditStatus.new
        )
    }
}
