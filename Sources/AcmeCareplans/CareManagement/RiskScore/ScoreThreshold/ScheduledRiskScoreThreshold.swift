import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled risk score threshold is in its life cycle.
    enum ScheduledRiskScoreThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A scheduled risk score threshold. Its code is unique within a tenant.
    final class ScheduledRiskScoreThreshold {
        var code: String
        var title: String
        var budget: Double
        var priority: Int
        var margin: Double
        var unit: String
        var capacity: Int
        var facility: String
        var status: ScheduledRiskScoreThresholdStatus

        init(code: String, title: String, budget: Double, priority: Int, margin: Double, unit: String, capacity: Int, facility: String, status: ScheduledRiskScoreThresholdStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.priority = priority
            self.margin = margin
            self.unit = unit
            self.capacity = capacity
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledRiskScoreThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledRiskScoreThresholdStatus.resolved || next == ScheduledRiskScoreThresholdStatus.archived
            case .inReview:
                return next == ScheduledRiskScoreThresholdStatus.reopened || next == ScheduledRiskScoreThresholdStatus.archived
            case .resolved:
                return next == ScheduledRiskScoreThresholdStatus.reopened || next == ScheduledRiskScoreThresholdStatus.archived
            case .reopened:
                return next == ScheduledRiskScoreThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledRiskScoreThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled risk score threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return ((Double(capacity) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRiskScoreThreshold {
            return ScheduledRiskScoreThreshold(
                code: code,
                title: title,
                budget: budget,
                priority: priority,
                margin: margin,
                unit: unit,
                capacity: capacity,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled risk score threshold in status open.
    static func newScheduledRiskScoreThreshold(_ code: String, title: String) -> ScheduledRiskScoreThreshold {
        return ScheduledRiskScoreThreshold(
            code: code,
            title: title,
            budget: 0.0,
            priority: 0,
            margin: 0.0,
            unit: "",
            capacity: 0,
            facility: "",
            status: ScheduledRiskScoreThresholdStatus.`open`
        )
    }
}
