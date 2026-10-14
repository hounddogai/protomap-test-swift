import AcmePlatform
import Foundation

extension Labs {
    /// Where a tiered panel plan is in its life cycle.
    enum TieredPanelPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered panel plan and its current status.
    final class TieredPanelPlan {
        var code: String
        var title: String
        var active: Bool
        var margin: Double
        var bed: String
        var quantity: Int
        var description: String
        var status: TieredPanelPlanStatus

        init(code: String, title: String, active: Bool, margin: Double, bed: String, quantity: Int, description: String, status: TieredPanelPlanStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.margin = margin
            self.bed = bed
            self.quantity = quantity
            self.description = description
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

        func canMoveTo(_ next: TieredPanelPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredPanelPlanStatus.suspended || next == TieredPanelPlanStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredPanelPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPanelPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered panel plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedExposure() -> Double {
            return (Double(quantity) * margin * 100).rounded() / 100
        }

        func copyValue() -> TieredPanelPlan {
            return TieredPanelPlan(
                code: code,
                title: title,
                active: active,
                margin: margin,
                bed: bed,
                quantity: quantity,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered panel plan in status draft.
    static func newTieredPanelPlan(_ code: String, title: String) -> TieredPanelPlan {
        return TieredPanelPlan(
            code: code,
            title: title,
            active: false,
            margin: 0.0,
            bed: "",
            quantity: 0,
            description: "",
            status: TieredPanelPlanStatus.draft
        )
    }
}
