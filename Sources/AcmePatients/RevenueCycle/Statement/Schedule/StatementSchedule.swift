import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement schedule is in its life cycle.
    enum StatementScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A statement schedule as the statement team keeps it.
    final class StatementSchedule {
        var code: String
        var label: String
        var startsAt: Int
        var updatedAt: Int
        var name: String
        var amount: Double
        var revision: Int
        var status: StatementScheduleStatus

        init(code: String, label: String, startsAt: Int, updatedAt: Int, name: String, amount: Double, revision: Int, status: StatementScheduleStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.updatedAt = updatedAt
            self.name = name
            self.amount = amount
            self.revision = revision
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

        func canMoveTo(_ next: StatementScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == StatementScheduleStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StatementScheduleStatus.cancelled
            case .completed:
                return next == StatementScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return (Double(startsAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> StatementSchedule {
            return StatementSchedule(
                code: code,
                label: label,
                startsAt: startsAt,
                updatedAt: updatedAt,
                name: name,
                amount: amount,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement schedule in status planned.
    static func newStatementSchedule(_ code: String, label: String) -> StatementSchedule {
        return StatementSchedule(
            code: code,
            label: label,
            startsAt: 0,
            updatedAt: 0,
            name: "",
            amount: 0.0,
            revision: 0,
            status: StatementScheduleStatus.planned
        )
    }
}
