import AcmePlatform
import Foundation

extension Labs {
    /// Where a result request is in its life cycle.
    enum ResultRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A result request. Its code is unique within a tenant.
    final class ResultRequest {
        var code: String
        var title: String
        var amount: Double
        var createdAt: Int
        var refills: Int
        var status: ResultRequestStatus

        init(code: String, title: String, amount: Double, createdAt: Int, refills: Int, status: ResultRequestStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.createdAt = createdAt
            self.refills = refills
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

        func canMoveTo(_ next: ResultRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == ResultRequestStatus.draining || next == ResultRequestStatus.stopped
            case .warming:
                return next == ResultRequestStatus.stopped
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

        func moveTo(_ next: ResultRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return (amount * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> ResultRequest {
            return ResultRequest(
                code: code,
                title: title,
                amount: amount,
                createdAt: createdAt,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result request in status idle.
    static func newResultRequest(_ code: String, title: String) -> ResultRequest {
        return ResultRequest(
            code: code,
            title: title,
            amount: 0.0,
            createdAt: 0,
            refills: 0,
            status: ResultRequestStatus.idle
        )
    }
}
