import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff audit is in its life cycle.
    enum HandoffAuditStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A handoff audit. Its code is unique within a tenant.
    final class HandoffAudit {
        var code: String
        var label: String
        var sequence: Int
        var channel: String
        var ceiling: Double
        var approved: Bool
        var bed: String
        var status: HandoffAuditStatus

        init(code: String, label: String, sequence: Int, channel: String, ceiling: Double, approved: Bool, bed: String, status: HandoffAuditStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.channel = channel
            self.ceiling = ceiling
            self.approved = approved
            self.bed = bed
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

        func canMoveTo(_ next: HandoffAuditStatus) -> Bool {
            switch status {
            case .planned:
                return next == HandoffAuditStatus.cancelled
            case .scheduled:
                return next == HandoffAuditStatus.completed || next == HandoffAuditStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == HandoffAuditStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("handoff audit") \(code)"
        }

        func netExposure() -> Double {
            return ((ceiling - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffAudit {
            return HandoffAudit(
                code: code,
                label: label,
                sequence: sequence,
                channel: channel,
                ceiling: ceiling,
                approved: approved,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a handoff audit in status planned.
    static func newHandoffAudit(_ code: String, label: String) -> HandoffAudit {
        return HandoffAudit(
            code: code,
            label: label,
            sequence: 0,
            channel: "",
            ceiling: 0.0,
            approved: false,
            bed: "",
            status: HandoffAuditStatus.planned
        )
    }
}
