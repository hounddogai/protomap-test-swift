import AcmePlatform
import Foundation

extension Staffing {
    /// Where a rolling overtime budget is in its life cycle.
    enum RollingOvertimeBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rolling overtime budget, with what the planners need to act on it.
    final class RollingOvertimeBudget {
        var code: String
        var title: String
        var procedureCode: String
        var description: String
        var country: String
        var diagnosisCode: String
        var quantity: Int
        var segment: String
        var archived: Bool
        var status: RollingOvertimeBudgetStatus

        init(code: String, title: String, procedureCode: String, description: String, country: String, diagnosisCode: String, quantity: Int, segment: String, archived: Bool, status: RollingOvertimeBudgetStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.description = description
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.quantity = quantity
            self.segment = segment
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingOvertimeBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingOvertimeBudgetStatus.warming || next == RollingOvertimeBudgetStatus.stopped
            case .warming:
                return next == RollingOvertimeBudgetStatus.draining || next == RollingOvertimeBudgetStatus.stopped
            case .ready:
                return next == RollingOvertimeBudgetStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RollingOvertimeBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling overtime budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RollingOvertimeBudget {
            return RollingOvertimeBudget(
                code: code,
                title: title,
                procedureCode: procedureCode,
                description: description,
                country: country,
                diagnosisCode: diagnosisCode,
                quantity: quantity,
                segment: segment,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling overtime budget in status idle.
    static func newRollingOvertimeBudget(_ code: String, title: String) -> RollingOvertimeBudget {
        return RollingOvertimeBudget(
            code: code,
            title: title,
            procedureCode: "",
            description: "",
            country: "",
            diagnosisCode: "",
            quantity: 0,
            segment: "",
            archived: false,
            status: RollingOvertimeBudgetStatus.idle
        )
    }
}
