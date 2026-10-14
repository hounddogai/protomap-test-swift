import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted assessment budget is in its life cycle.
    enum WeightedAssessmentBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a weighted assessment budget and its current status.
    final class WeightedAssessmentBudget {
        var code: String
        var title: String
        var capacity: Int
        var quantity: Int
        var rate: Double
        var discount: Double
        var acuity: Int
        var archived: Bool
        var visible: Bool
        var tags: [String]
        var active: Bool
        var status: WeightedAssessmentBudgetStatus

        init(code: String, title: String, capacity: Int, quantity: Int, rate: Double, discount: Double, acuity: Int, archived: Bool, visible: Bool, tags: [String], active: Bool, status: WeightedAssessmentBudgetStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.quantity = quantity
            self.rate = rate
            self.discount = discount
            self.acuity = acuity
            self.archived = archived
            self.visible = visible
            self.tags = tags
            self.active = active
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

        func canMoveTo(_ next: WeightedAssessmentBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == WeightedAssessmentBudgetStatus.suspended || next == WeightedAssessmentBudgetStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: WeightedAssessmentBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted assessment budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(capacity) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAssessmentBudget {
            return WeightedAssessmentBudget(
                code: code,
                title: title,
                capacity: capacity,
                quantity: quantity,
                rate: rate,
                discount: discount,
                acuity: acuity,
                archived: archived,
                visible: visible,
                tags: tags,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted assessment budget in status draft.
    static func newWeightedAssessmentBudget(_ code: String, title: String) -> WeightedAssessmentBudget {
        return WeightedAssessmentBudget(
            code: code,
            title: title,
            capacity: 0,
            quantity: 0,
            rate: 0.0,
            discount: 0.0,
            acuity: 0,
            archived: false,
            visible: false,
            tags: [],
            active: false,
            status: WeightedAssessmentBudgetStatus.draft
        )
    }
}
