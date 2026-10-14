import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization record is in its life cycle.
    enum AuthorizationRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a authorization record and its current status.
    final class AuthorizationRecord {
        var code: String
        var name: String
        var attempts: Int
        var patientRef: String
        var discount: Double
        var cost: Double
        var timezone: String
        var amount: Double
        var status: AuthorizationRecordStatus

        init(code: String, name: String, attempts: Int, patientRef: String, discount: Double, cost: Double, timezone: String, amount: Double, status: AuthorizationRecordStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.patientRef = patientRef
            self.discount = discount
            self.cost = cost
            self.timezone = timezone
            self.amount = amount
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

        func canMoveTo(_ next: AuthorizationRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == AuthorizationRecordStatus.done
            case .queued:
                return next == AuthorizationRecordStatus.done
            case .running:
                return next == AuthorizationRecordStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AuthorizationRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return (discount * cost * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationRecord {
            return AuthorizationRecord(
                code: code,
                name: name,
                attempts: attempts,
                patientRef: patientRef,
                discount: discount,
                cost: cost,
                timezone: timezone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a authorization record in status new.
    static func newAuthorizationRecord(_ code: String, name: String) -> AuthorizationRecord {
        return AuthorizationRecord(
            code: code,
            name: name,
            attempts: 0,
            patientRef: "",
            discount: 0.0,
            cost: 0.0,
            timezone: "",
            amount: 0.0,
            status: AuthorizationRecordStatus.new
        )
    }
}
