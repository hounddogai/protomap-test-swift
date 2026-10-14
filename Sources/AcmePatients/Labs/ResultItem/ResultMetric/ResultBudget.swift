import AcmePlatform
import Foundation

extension Labs {
    /// Where a result budget is in its life cycle.
    enum ResultBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A result budget. Its code is unique within a tenant.
    final class ResultBudget {
        var code: String
        var title: String
        var summary: String
        var currency: String
        var margin: Double
        var status: ResultBudgetStatus

        init(code: String, title: String, summary: String, currency: String, margin: Double, status: ResultBudgetStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.currency = currency
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ResultBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("result budget") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> ResultBudget {
            return ResultBudget(
                code: code,
                title: title,
                summary: summary,
                currency: currency,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result budget in status new.
    static func newResultBudget(_ code: String, title: String) -> ResultBudget {
        return ResultBudget(
            code: code,
            title: title,
            summary: "",
            currency: "",
            margin: 0.0,
            status: ResultBudgetStatus.new
        )
    }
}
