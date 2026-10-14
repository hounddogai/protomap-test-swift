import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default shift template is in its life cycle.
    enum DefaultShiftTemplateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default shift template. Its code is unique within a tenant.
    final class DefaultShiftTemplate {
        var code: String
        var label: String
        var summary: String
        var visitMinutes: Int
        var durationMinutes: Int
        var budget: Double
        var updatedAt: Int
        var status: DefaultShiftTemplateStatus

        init(code: String, label: String, summary: String, visitMinutes: Int, durationMinutes: Int, budget: Double, updatedAt: Int, status: DefaultShiftTemplateStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.durationMinutes = durationMinutes
            self.budget = budget
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: DefaultShiftTemplateStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultShiftTemplateStatus.published || next == DefaultShiftTemplateStatus.retired
            case .validated:
                return next == DefaultShiftTemplateStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DefaultShiftTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default shift template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("default shift template") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(visitMinutes) - budget) * 100).rounded() / 100
        }

        func copyValue() -> DefaultShiftTemplate {
            return DefaultShiftTemplate(
                code: code,
                label: label,
                summary: summary,
                visitMinutes: visitMinutes,
                durationMinutes: durationMinutes,
                budget: budget,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default shift template in status created.
    static func newDefaultShiftTemplate(_ code: String, label: String) -> DefaultShiftTemplate {
        return DefaultShiftTemplate(
            code: code,
            label: label,
            summary: "",
            visitMinutes: 0,
            durationMinutes: 0,
            budget: 0.0,
            updatedAt: 0,
            status: DefaultShiftTemplateStatus.created
        )
    }
}
