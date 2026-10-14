import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance schedule is in its life cycle.
    enum RemittanceScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a remittance schedule and its current status.
    final class RemittanceSchedule {
        var code: String
        var title: String
        var cost: Double
        var currency: String
        var ceiling: Double
        var createdAt: Int
        var procedureCode: String
        var threshold: Double
        var priority: Int
        var visitMinutes: Int
        var durationMinutes: Int
        var status: RemittanceScheduleStatus

        init(code: String, title: String, cost: Double, currency: String, ceiling: Double, createdAt: Int, procedureCode: String, threshold: Double, priority: Int, visitMinutes: Int, durationMinutes: Int, status: RemittanceScheduleStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.currency = currency
            self.ceiling = ceiling
            self.createdAt = createdAt
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.priority = priority
            self.visitMinutes = visitMinutes
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: RemittanceScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == RemittanceScheduleStatus.inProgress || next == RemittanceScheduleStatus.cancelled
            case .scheduled:
                return next == RemittanceScheduleStatus.completed
            case .inProgress:
                return next == RemittanceScheduleStatus.completed || next == RemittanceScheduleStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RemittanceScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedValue() -> Double {
            return ((threshold - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceSchedule {
            return RemittanceSchedule(
                code: code,
                title: title,
                cost: cost,
                currency: currency,
                ceiling: ceiling,
                createdAt: createdAt,
                procedureCode: procedureCode,
                threshold: threshold,
                priority: priority,
                visitMinutes: visitMinutes,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance schedule in status planned.
    static func newRemittanceSchedule(_ code: String, title: String) -> RemittanceSchedule {
        return RemittanceSchedule(
            code: code,
            title: title,
            cost: 0.0,
            currency: "",
            ceiling: 0.0,
            createdAt: 0,
            procedureCode: "",
            threshold: 0.0,
            priority: 0,
            visitMinutes: 0,
            durationMinutes: 0,
            status: RemittanceScheduleStatus.planned
        )
    }
}
