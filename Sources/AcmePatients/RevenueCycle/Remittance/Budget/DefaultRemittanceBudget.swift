import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance budget is in its life cycle.
    enum DefaultRemittanceBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default remittance budget as the remittance team keeps it.
    final class DefaultRemittanceBudget {
        var code: String
        var title: String
        var archived: Bool
        var sequence: Int
        var createdAt: Int
        var status: DefaultRemittanceBudgetStatus

        init(code: String, title: String, archived: Bool, sequence: Int, createdAt: Int, status: DefaultRemittanceBudgetStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.sequence = sequence
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultRemittanceBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultRemittanceBudgetStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRemittanceBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default remittance budget") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceBudget {
            return DefaultRemittanceBudget(
                code: code,
                title: title,
                archived: archived,
                sequence: sequence,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default remittance budget in status requested.
    static func newDefaultRemittanceBudget(_ code: String, title: String) -> DefaultRemittanceBudget {
        return DefaultRemittanceBudget(
            code: code,
            title: title,
            archived: false,
            sequence: 0,
            createdAt: 0,
            status: DefaultRemittanceBudgetStatus.requested
        )
    }
}
