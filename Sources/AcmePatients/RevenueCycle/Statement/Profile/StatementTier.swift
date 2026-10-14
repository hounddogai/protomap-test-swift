import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement tier is in its life cycle.
    enum StatementTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A statement tier. Its code is unique within a tenant.
    final class StatementTier {
        var code: String
        var name: String
        var phone: String
        var weight: Double
        var title: String
        var specialty: String
        var contactEmail: String
        var status: StatementTierStatus

        init(code: String, name: String, phone: String, weight: Double, title: String, specialty: String, contactEmail: String, status: StatementTierStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.weight = weight
            self.title = title
            self.specialty = specialty
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementTierStatus) -> Bool {
            switch status {
            case .draft:
                return next == StatementTierStatus.pending
            case .pending:
                return next == StatementTierStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == StatementTierStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> StatementTier {
            return StatementTier(
                code: code,
                name: name,
                phone: phone,
                weight: weight,
                title: title,
                specialty: specialty,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement tier in status draft.
    static func newStatementTier(_ code: String, name: String) -> StatementTier {
        return StatementTier(
            code: code,
            name: name,
            phone: "",
            weight: 0.0,
            title: "",
            specialty: "",
            contactEmail: "",
            status: StatementTierStatus.draft
        )
    }
}
