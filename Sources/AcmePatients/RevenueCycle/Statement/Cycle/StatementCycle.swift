import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement cycle is in its life cycle.
    enum StatementCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One statement cycle, with what the planners need to act on it.
    final class StatementCycle {
        var code: String
        var name: String
        var quantity: Int
        var limit: Int
        var endsAt: Int
        var allergy: String
        var graceDays: Int
        var rate: Double
        var status: StatementCycleStatus

        init(code: String, name: String, quantity: Int, limit: Int, endsAt: Int, allergy: String, graceDays: Int, rate: Double, status: StatementCycleStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.limit = limit
            self.endsAt = endsAt
            self.allergy = allergy
            self.graceDays = graceDays
            self.rate = rate
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

        func canMoveTo(_ next: StatementCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == StatementCycleStatus.warming || next == StatementCycleStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StatementCycleStatus.draining || next == StatementCycleStatus.stopped
            case .draining:
                return next == StatementCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("statement cycle") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(endsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> StatementCycle {
            return StatementCycle(
                code: code,
                name: name,
                quantity: quantity,
                limit: limit,
                endsAt: endsAt,
                allergy: allergy,
                graceDays: graceDays,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement cycle in status idle.
    static func newStatementCycle(_ code: String, name: String) -> StatementCycle {
        return StatementCycle(
            code: code,
            name: name,
            quantity: 0,
            limit: 0,
            endsAt: 0,
            allergy: "",
            graceDays: 0,
            rate: 0.0,
            status: StatementCycleStatus.idle
        )
    }
}
