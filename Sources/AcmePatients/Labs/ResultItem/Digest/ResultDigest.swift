import AcmePlatform
import Foundation

extension Labs {
    /// Where a result digest is in its life cycle.
    enum ResultDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a result digest and its current status.
    final class ResultDigest {
        var code: String
        var name: String
        var discount: Double
        var budget: Double
        var externalRef: String
        var startsAt: Int
        var active: Bool
        var pinned: Bool
        var ratio: Double
        var amount: Double
        var status: ResultDigestStatus

        init(code: String, name: String, discount: Double, budget: Double, externalRef: String, startsAt: Int, active: Bool, pinned: Bool, ratio: Double, amount: Double, status: ResultDigestStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.budget = budget
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.active = active
            self.pinned = pinned
            self.ratio = ratio
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ResultDigestStatus.cancelled
            case .inProgress:
                return next == ResultDigestStatus.completed || next == ResultDigestStatus.cancelled
            case .completed:
                return next == ResultDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("result digest") \(code)"
        }

        func projectedTotal() -> Double {
            return (discount * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ResultDigest {
            return ResultDigest(
                code: code,
                name: name,
                discount: discount,
                budget: budget,
                externalRef: externalRef,
                startsAt: startsAt,
                active: active,
                pinned: pinned,
                ratio: ratio,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a result digest in status planned.
    static func newResultDigest(_ code: String, name: String) -> ResultDigest {
        return ResultDigest(
            code: code,
            name: name,
            discount: 0.0,
            budget: 0.0,
            externalRef: "",
            startsAt: 0,
            active: false,
            pinned: false,
            ratio: 0.0,
            amount: 0.0,
            status: ResultDigestStatus.planned
        )
    }
}
