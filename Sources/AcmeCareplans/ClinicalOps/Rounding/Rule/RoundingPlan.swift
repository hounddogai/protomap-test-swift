import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding plan is in its life cycle.
    enum RoundingPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a rounding plan and its current status.
    final class RoundingPlan {
        var code: String
        var title: String
        var ceiling: Double
        var capacity: Int
        var summary: String
        var country: String
        var archived: Bool
        var status: RoundingPlanStatus

        init(code: String, title: String, ceiling: Double, capacity: Int, summary: String, country: String, archived: Bool, status: RoundingPlanStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.capacity = capacity
            self.summary = summary
            self.country = country
            self.archived = archived
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

        func canMoveTo(_ next: RoundingPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == RoundingPlanStatus.pending
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RoundingPlanStatus.closed
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

        func moveTo(_ next: RoundingPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rounding plan") \(code)"
        }

        func projectedValue() -> Double {
            return ((ceiling + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingPlan {
            return RoundingPlan(
                code: code,
                title: title,
                ceiling: ceiling,
                capacity: capacity,
                summary: summary,
                country: country,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rounding plan in status draft.
    static func newRoundingPlan(_ code: String, title: String) -> RoundingPlan {
        return RoundingPlan(
            code: code,
            title: title,
            ceiling: 0.0,
            capacity: 0,
            summary: "",
            country: "",
            archived: false,
            status: RoundingPlanStatus.draft
        )
    }
}
