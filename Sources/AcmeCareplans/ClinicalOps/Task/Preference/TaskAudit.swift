import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task audit is in its life cycle.
    enum TaskAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A task audit. Its code is unique within a tenant.
    final class TaskAudit {
        var code: String
        var label: String
        var ward: String
        var channel: String
        var amount: Double
        var attributes: [String: String]
        var status: TaskAuditStatus

        init(code: String, label: String, ward: String, channel: String, amount: Double, attributes: [String: String], status: TaskAuditStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.channel = channel
            self.amount = amount
            self.attributes = attributes
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

        func canMoveTo(_ next: TaskAuditStatus) -> Bool {
            switch status {
            case .proposed:
                return next == TaskAuditStatus.approved || next == TaskAuditStatus.rejected
            case .approved:
                return next == TaskAuditStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: TaskAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> TaskAudit {
            return TaskAudit(
                code: code,
                label: label,
                ward: ward,
                channel: channel,
                amount: amount,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a task audit in status proposed.
    static func newTaskAudit(_ code: String, label: String) -> TaskAudit {
        return TaskAudit(
            code: code,
            label: label,
            ward: "",
            channel: "",
            amount: 0.0,
            attributes: [:],
            status: TaskAuditStatus.proposed
        )
    }
}
