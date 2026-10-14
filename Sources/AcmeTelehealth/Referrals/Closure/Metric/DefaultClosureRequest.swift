import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default closure request is in its life cycle.
    enum DefaultClosureRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a default closure request and its current status.
    final class DefaultClosureRequest {
        var code: String
        var title: String
        var discount: Double
        var dosageMg: Double
        var updatedAt: Int
        var tags: [String]
        var status: DefaultClosureRequestStatus

        init(code: String, title: String, discount: Double, dosageMg: Double, updatedAt: Int, tags: [String], status: DefaultClosureRequestStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.tags = tags
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

        func canMoveTo(_ next: DefaultClosureRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == DefaultClosureRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultClosureRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default closure request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return ((Double(updatedAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> DefaultClosureRequest {
            return DefaultClosureRequest(
                code: code,
                title: title,
                discount: discount,
                dosageMg: dosageMg,
                updatedAt: updatedAt,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default closure request in status draft.
    static func newDefaultClosureRequest(_ code: String, title: String) -> DefaultClosureRequest {
        return DefaultClosureRequest(
            code: code,
            title: title,
            discount: 0.0,
            dosageMg: 0.0,
            updatedAt: 0,
            tags: [],
            status: DefaultClosureRequestStatus.draft
        )
    }
}
