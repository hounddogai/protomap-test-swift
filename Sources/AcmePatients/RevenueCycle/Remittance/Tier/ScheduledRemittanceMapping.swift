import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled remittance mapping is in its life cycle.
    enum ScheduledRemittanceMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled remittance mapping. Its code is unique within a tenant.
    final class ScheduledRemittanceMapping {
        var code: String
        var name: String
        var clinicianID: String
        var visitMinutes: Int
        var dosageMg: Double
        var minimum: Double
        var visible: Bool
        var title: String
        var batchSize: Int
        var status: ScheduledRemittanceMappingStatus

        init(code: String, name: String, clinicianID: String, visitMinutes: Int, dosageMg: Double, minimum: Double, visible: Bool, title: String, batchSize: Int, status: ScheduledRemittanceMappingStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.visible = visible
            self.title = title
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledRemittanceMappingStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledRemittanceMappingStatus.scheduled || next == ScheduledRemittanceMappingStatus.inProgress
            case .scheduled:
                return next == ScheduledRemittanceMappingStatus.inProgress || next == ScheduledRemittanceMappingStatus.completed
            case .inProgress:
                return next == ScheduledRemittanceMappingStatus.cancelled
            case .completed:
                return next == ScheduledRemittanceMappingStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledRemittanceMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled remittance mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return ((minimum + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRemittanceMapping {
            return ScheduledRemittanceMapping(
                code: code,
                name: name,
                clinicianID: clinicianID,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                minimum: minimum,
                visible: visible,
                title: title,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled remittance mapping in status planned.
    static func newScheduledRemittanceMapping(_ code: String, name: String) -> ScheduledRemittanceMapping {
        return ScheduledRemittanceMapping(
            code: code,
            name: name,
            clinicianID: "",
            visitMinutes: 0,
            dosageMg: 0.0,
            minimum: 0.0,
            visible: false,
            title: "",
            batchSize: 0,
            status: ScheduledRemittanceMappingStatus.planned
        )
    }
}
