import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization ledger is in its life cycle.
    enum AuthorizationLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a authorization ledger and its current status.
    final class AuthorizationLedger {
        var code: String
        var label: String
        var archived: Bool
        var category: String
        var endsAt: Int
        var specialty: String
        var rate: Double
        var durationMinutes: Int
        var expiresAt: Int
        var graceDays: Int
        var status: AuthorizationLedgerStatus

        init(code: String, label: String, archived: Bool, category: String, endsAt: Int, specialty: String, rate: Double, durationMinutes: Int, expiresAt: Int, graceDays: Int, status: AuthorizationLedgerStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.category = category
            self.endsAt = endsAt
            self.specialty = specialty
            self.rate = rate
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AuthorizationLedgerStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AuthorizationLedgerStatus.reopened || next == AuthorizationLedgerStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AuthorizationLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return (Double(expiresAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationLedger {
            return AuthorizationLedger(
                code: code,
                label: label,
                archived: archived,
                category: category,
                endsAt: endsAt,
                specialty: specialty,
                rate: rate,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a authorization ledger in status open.
    static func newAuthorizationLedger(_ code: String, label: String) -> AuthorizationLedger {
        return AuthorizationLedger(
            code: code,
            label: label,
            archived: false,
            category: "",
            endsAt: 0,
            specialty: "",
            rate: 0.0,
            durationMinutes: 0,
            expiresAt: 0,
            graceDays: 0,
            status: AuthorizationLedgerStatus.`open`
        )
    }
}
