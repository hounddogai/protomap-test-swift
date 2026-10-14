import AcmePlatform
import Foundation

extension Labs {
    /// Where a result plan is in its life cycle.
    enum ResultPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result plan. Its code is unique within a tenant.
    final class ResultPlan {
        var code: String
        var name: String
        var graceDays: Int
        var segment: String
        var notes: String
        var archived: Bool
        var amount: Double
        var status: ResultPlanStatus

        init(code: String, name: String, graceDays: Int, segment: String, notes: String, archived: Bool, amount: Double, status: ResultPlanStatus) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.segment = segment
            self.notes = notes
            self.archived = archived
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ResultPlanStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ResultPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((amount + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ResultPlan {
            return ResultPlan(
                code: code,
                name: name,
                graceDays: graceDays,
                segment: segment,
                notes: notes,
                archived: archived,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a result plan in status requested.
    static func newResultPlan(_ code: String, name: String) -> ResultPlan {
        return ResultPlan(
            code: code,
            name: name,
            graceDays: 0,
            segment: "",
            notes: "",
            archived: false,
            amount: 0.0,
            status: ResultPlanStatus.requested
        )
    }
}
