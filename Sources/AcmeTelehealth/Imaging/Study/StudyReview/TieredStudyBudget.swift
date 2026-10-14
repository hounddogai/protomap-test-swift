import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered study budget is in its life cycle.
    enum TieredStudyBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered study budget and its current status.
    final class TieredStudyBudget {
        var code: String
        var name: String
        var version: Int
        var timezone: String
        var copay: Double
        var discount: Double
        var archived: Bool
        var status: TieredStudyBudgetStatus

        init(code: String, name: String, version: Int, timezone: String, copay: Double, discount: Double, archived: Bool, status: TieredStudyBudgetStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.timezone = timezone
            self.copay = copay
            self.discount = discount
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

        func canMoveTo(_ next: TieredStudyBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredStudyBudgetStatus.suspended
            case .suspended:
                return next == TieredStudyBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredStudyBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered study budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((discount + copay) * 100).rounded() / 100
        }

        func copyValue() -> TieredStudyBudget {
            return TieredStudyBudget(
                code: code,
                name: name,
                version: version,
                timezone: timezone,
                copay: copay,
                discount: discount,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered study budget in status draft.
    static func newTieredStudyBudget(_ code: String, name: String) -> TieredStudyBudget {
        return TieredStudyBudget(
            code: code,
            name: name,
            version: 0,
            timezone: "",
            copay: 0.0,
            discount: 0.0,
            archived: false,
            status: TieredStudyBudgetStatus.draft
        )
    }
}
