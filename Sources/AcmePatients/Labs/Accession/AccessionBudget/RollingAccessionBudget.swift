import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession budget is in its life cycle.
    enum RollingAccessionBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rolling accession budget. Its code is unique within a tenant.
    final class RollingAccessionBudget {
        var code: String
        var title: String
        var description: String
        var ward: String
        var category: String
        var durationMinutes: Int
        var summary: String
        var status: RollingAccessionBudgetStatus

        init(code: String, title: String, description: String, ward: String, category: String, durationMinutes: Int, summary: String, status: RollingAccessionBudgetStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.ward = ward
            self.category = category
            self.durationMinutes = durationMinutes
            self.summary = summary
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

        func canMoveTo(_ next: RollingAccessionBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingAccessionBudgetStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingAccessionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> RollingAccessionBudget {
            return RollingAccessionBudget(
                code: code,
                title: title,
                description: description,
                ward: ward,
                category: category,
                durationMinutes: durationMinutes,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling accession budget in status open.
    static func newRollingAccessionBudget(_ code: String, title: String) -> RollingAccessionBudget {
        return RollingAccessionBudget(
            code: code,
            title: title,
            description: "",
            ward: "",
            category: "",
            durationMinutes: 0,
            summary: "",
            status: RollingAccessionBudgetStatus.`open`
        )
    }
}
