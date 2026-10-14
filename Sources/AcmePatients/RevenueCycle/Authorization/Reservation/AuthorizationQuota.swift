import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization quota is in its life cycle.
    enum AuthorizationQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A authorization quota. Its code is unique within a tenant.
    final class AuthorizationQuota {
        var code: String
        var name: String
        var maximum: Double
        var contactEmail: String
        var limit: Int
        var refills: Int
        var discount: Double
        var notes: String
        var quantity: Int
        var status: AuthorizationQuotaStatus

        init(code: String, name: String, maximum: Double, contactEmail: String, limit: Int, refills: Int, discount: Double, notes: String, quantity: Int, status: AuthorizationQuotaStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.limit = limit
            self.refills = refills
            self.discount = discount
            self.notes = notes
            self.quantity = quantity
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

        func canMoveTo(_ next: AuthorizationQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AuthorizationQuotaStatus.failed
            case .done:
                return next == AuthorizationQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return (maximum * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationQuota {
            return AuthorizationQuota(
                code: code,
                name: name,
                maximum: maximum,
                contactEmail: contactEmail,
                limit: limit,
                refills: refills,
                discount: discount,
                notes: notes,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a authorization quota in status new.
    static func newAuthorizationQuota(_ code: String, name: String) -> AuthorizationQuota {
        return AuthorizationQuota(
            code: code,
            name: name,
            maximum: 0.0,
            contactEmail: "",
            limit: 0,
            refills: 0,
            discount: 0.0,
            notes: "",
            quantity: 0,
            status: AuthorizationQuotaStatus.new
        )
    }
}
