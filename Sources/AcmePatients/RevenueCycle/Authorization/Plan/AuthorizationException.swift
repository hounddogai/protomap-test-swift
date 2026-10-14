import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization exception is in its life cycle.
    enum AuthorizationExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a authorization exception and its current status.
    final class AuthorizationException {
        var code: String
        var title: String
        var amount: Double
        var batchSize: Int
        var refills: Int
        var allergy: String
        var revision: Int
        var status: AuthorizationExceptionStatus

        init(code: String, title: String, amount: Double, batchSize: Int, refills: Int, allergy: String, revision: Int, status: AuthorizationExceptionStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.batchSize = batchSize
            self.refills = refills
            self.allergy = allergy
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationExceptionStatus) -> Bool {
            switch status {
            case .created:
                return next == AuthorizationExceptionStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AuthorizationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((amount + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationException {
            return AuthorizationException(
                code: code,
                title: title,
                amount: amount,
                batchSize: batchSize,
                refills: refills,
                allergy: allergy,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization exception in status created.
    static func newAuthorizationException(_ code: String, title: String) -> AuthorizationException {
        return AuthorizationException(
            code: code,
            title: title,
            amount: 0.0,
            batchSize: 0,
            refills: 0,
            allergy: "",
            revision: 0,
            status: AuthorizationExceptionStatus.created
        )
    }
}
