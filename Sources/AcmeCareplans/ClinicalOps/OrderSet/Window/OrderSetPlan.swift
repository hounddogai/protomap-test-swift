import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set plan is in its life cycle.
    enum OrderSetPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A order set plan as the order set team keeps it.
    final class OrderSetPlan {
        var code: String
        var title: String
        var summary: String
        var endsAt: Int
        var ceiling: Double
        var copay: Double
        var amount: Double
        var discount: Double
        var status: OrderSetPlanStatus

        init(code: String, title: String, summary: String, endsAt: Int, ceiling: Double, copay: Double, amount: Double, discount: Double, status: OrderSetPlanStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.copay = copay
            self.amount = amount
            self.discount = discount
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

        func canMoveTo(_ next: OrderSetPlanStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == OrderSetPlanStatus.reopened
            case .resolved:
                return next == OrderSetPlanStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: OrderSetPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) - amount) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetPlan {
            return OrderSetPlan(
                code: code,
                title: title,
                summary: summary,
                endsAt: endsAt,
                ceiling: ceiling,
                copay: copay,
                amount: amount,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set plan in status open.
    static func newOrderSetPlan(_ code: String, title: String) -> OrderSetPlan {
        return OrderSetPlan(
            code: code,
            title: title,
            summary: "",
            endsAt: 0,
            ceiling: 0.0,
            copay: 0.0,
            amount: 0.0,
            discount: 0.0,
            status: OrderSetPlanStatus.`open`
        )
    }
}
