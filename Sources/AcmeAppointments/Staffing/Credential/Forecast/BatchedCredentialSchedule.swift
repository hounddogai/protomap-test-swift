import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched credential schedule is in its life cycle.
    enum BatchedCredentialScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched credential schedule. Its code is unique within a tenant.
    final class BatchedCredentialSchedule {
        var code: String
        var label: String
        var createdAt: Int
        var maximum: Double
        var budget: Double
        var description: String
        var phone: String
        var unit: String
        var priority: Int
        var refills: Int
        var channel: String
        var status: BatchedCredentialScheduleStatus

        init(code: String, label: String, createdAt: Int, maximum: Double, budget: Double, description: String, phone: String, unit: String, priority: Int, refills: Int, channel: String, status: BatchedCredentialScheduleStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.maximum = maximum
            self.budget = budget
            self.description = description
            self.phone = phone
            self.unit = unit
            self.priority = priority
            self.refills = refills
            self.channel = channel
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

        func canMoveTo(_ next: BatchedCredentialScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedCredentialScheduleStatus.pending || next == BatchedCredentialScheduleStatus.closed
            case .pending:
                return next == BatchedCredentialScheduleStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == BatchedCredentialScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCredentialScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched credential schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (budget * maximum * 100).rounded() / 100
        }

        func copyValue() -> BatchedCredentialSchedule {
            return BatchedCredentialSchedule(
                code: code,
                label: label,
                createdAt: createdAt,
                maximum: maximum,
                budget: budget,
                description: description,
                phone: phone,
                unit: unit,
                priority: priority,
                refills: refills,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched credential schedule in status draft.
    static func newBatchedCredentialSchedule(_ code: String, label: String) -> BatchedCredentialSchedule {
        return BatchedCredentialSchedule(
            code: code,
            label: label,
            createdAt: 0,
            maximum: 0.0,
            budget: 0.0,
            description: "",
            phone: "",
            unit: "",
            priority: 0,
            refills: 0,
            channel: "",
            status: BatchedCredentialScheduleStatus.draft
        )
    }
}
