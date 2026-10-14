import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert budget is in its life cycle.
    enum AlertBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One alert budget, with what the planners need to act on it.
    final class AlertBudget {
        var code: String
        var title: String
        var createdAt: Int
        var notes: String
        var ceiling: Double
        var segment: String
        var discount: Double
        var reviewer: String
        var endsAt: Int
        var status: AlertBudgetStatus

        init(code: String, title: String, createdAt: Int, notes: String, ceiling: Double, segment: String, discount: Double, reviewer: String, endsAt: Int, status: AlertBudgetStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.notes = notes
            self.ceiling = ceiling
            self.segment = segment
            self.discount = discount
            self.reviewer = reviewer
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AlertBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AlertBudgetStatus.rejected || next == AlertBudgetStatus.withdrawn
            case .approved:
                return next == AlertBudgetStatus.withdrawn
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

        func moveTo(_ next: AlertBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) + discount) * 100).rounded() / 100
        }

        func copyValue() -> AlertBudget {
            return AlertBudget(
                code: code,
                title: title,
                createdAt: createdAt,
                notes: notes,
                ceiling: ceiling,
                segment: segment,
                discount: discount,
                reviewer: reviewer,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a alert budget in status proposed.
    static func newAlertBudget(_ code: String, title: String) -> AlertBudget {
        return AlertBudget(
            code: code,
            title: title,
            createdAt: 0,
            notes: "",
            ceiling: 0.0,
            segment: "",
            discount: 0.0,
            reviewer: "",
            endsAt: 0,
            status: AlertBudgetStatus.proposed
        )
    }
}
