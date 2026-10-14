import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement target is in its life cycle.
    enum StatementTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One statement target, with what the planners need to act on it.
    final class StatementTarget {
        var code: String
        var name: String
        var ratio: Double
        var durationMinutes: Int
        var currency: String
        var phone: String
        var rate: Double
        var updatedAt: Int
        var createdAt: Int
        var status: StatementTargetStatus

        init(code: String, name: String, ratio: Double, durationMinutes: Int, currency: String, phone: String, rate: Double, updatedAt: Int, createdAt: Int, status: StatementTargetStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.phone = phone
            self.rate = rate
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementTargetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == StatementTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((ratio - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StatementTarget {
            return StatementTarget(
                code: code,
                name: name,
                ratio: ratio,
                durationMinutes: durationMinutes,
                currency: currency,
                phone: phone,
                rate: rate,
                updatedAt: updatedAt,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement target in status proposed.
    static func newStatementTarget(_ code: String, name: String) -> StatementTarget {
        return StatementTarget(
            code: code,
            name: name,
            ratio: 0.0,
            durationMinutes: 0,
            currency: "",
            phone: "",
            rate: 0.0,
            updatedAt: 0,
            createdAt: 0,
            status: StatementTargetStatus.proposed
        )
    }
}
