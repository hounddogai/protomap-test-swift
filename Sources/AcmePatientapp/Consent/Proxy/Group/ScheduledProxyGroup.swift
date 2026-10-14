import AcmePlatform
import Foundation

extension Consent {
    /// Where a scheduled proxy group is in its life cycle.
    enum ScheduledProxyGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled proxy group as the proxy team keeps it.
    final class ScheduledProxyGroup {
        var code: String
        var label: String
        var capacity: Int
        var updatedAt: Int
        var patientRef: String
        var batchSize: Int
        var clinicianID: String
        var ceiling: Double
        var sequence: Int
        var status: ScheduledProxyGroupStatus

        init(code: String, label: String, capacity: Int, updatedAt: Int, patientRef: String, batchSize: Int, clinicianID: String, ceiling: Double, sequence: Int, status: ScheduledProxyGroupStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.sequence = sequence
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

        func canMoveTo(_ next: ScheduledProxyGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == ScheduledProxyGroupStatus.scheduled || next == ScheduledProxyGroupStatus.completed
            case .scheduled:
                return next == ScheduledProxyGroupStatus.inProgress
            case .inProgress:
                return next == ScheduledProxyGroupStatus.completed || next == ScheduledProxyGroupStatus.cancelled
            case .completed:
                return next == ScheduledProxyGroupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledProxyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled proxy group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return ((ceiling + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProxyGroup {
            return ScheduledProxyGroup(
                code: code,
                label: label,
                capacity: capacity,
                updatedAt: updatedAt,
                patientRef: patientRef,
                batchSize: batchSize,
                clinicianID: clinicianID,
                ceiling: ceiling,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled proxy group in status planned.
    static func newScheduledProxyGroup(_ code: String, label: String) -> ScheduledProxyGroup {
        return ScheduledProxyGroup(
            code: code,
            label: label,
            capacity: 0,
            updatedAt: 0,
            patientRef: "",
            batchSize: 0,
            clinicianID: "",
            ceiling: 0.0,
            sequence: 0,
            status: ScheduledProxyGroupStatus.planned
        )
    }
}
