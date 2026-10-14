import AcmePlatform
import Foundation

extension Labs {
    /// Where a result baseline is in its life cycle.
    enum ResultBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A result baseline as the result team keeps it.
    final class ResultBaseline {
        var code: String
        var title: String
        var retries: Int
        var category: String
        var score: Double
        var pinned: Bool
        var amount: Double
        var status: ResultBaselineStatus

        init(code: String, title: String, retries: Int, category: String, score: Double, pinned: Bool, amount: Double, status: ResultBaselineStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.category = category
            self.score = score
            self.pinned = pinned
            self.amount = amount
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

        func canMoveTo(_ next: ResultBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == ResultBaselineStatus.warming || next == ResultBaselineStatus.ready
            case .warming:
                return next == ResultBaselineStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ResultBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(retries) - score) * 100).rounded() / 100
        }

        func copyValue() -> ResultBaseline {
            return ResultBaseline(
                code: code,
                title: title,
                retries: retries,
                category: category,
                score: score,
                pinned: pinned,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a result baseline in status idle.
    static func newResultBaseline(_ code: String, title: String) -> ResultBaseline {
        return ResultBaseline(
            code: code,
            title: title,
            retries: 0,
            category: "",
            score: 0.0,
            pinned: false,
            amount: 0.0,
            status: ResultBaselineStatus.idle
        )
    }
}
