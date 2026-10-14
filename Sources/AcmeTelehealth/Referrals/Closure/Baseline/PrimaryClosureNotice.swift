import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary closure notice is in its life cycle.
    enum PrimaryClosureNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a primary closure notice and its current status.
    final class PrimaryClosureNotice {
        var code: String
        var title: String
        var approved: Bool
        var visible: Bool
        var limit: Int
        var budget: Double
        var status: PrimaryClosureNoticeStatus

        init(code: String, title: String, approved: Bool, visible: Bool, limit: Int, budget: Double, status: PrimaryClosureNoticeStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.visible = visible
            self.limit = limit
            self.budget = budget
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

        func canMoveTo(_ next: PrimaryClosureNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryClosureNoticeStatus.active || next == PrimaryClosureNoticeStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryClosureNoticeStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PrimaryClosureNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary closure notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return (budget * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryClosureNotice {
            return PrimaryClosureNotice(
                code: code,
                title: title,
                approved: approved,
                visible: visible,
                limit: limit,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary closure notice in status draft.
    static func newPrimaryClosureNotice(_ code: String, title: String) -> PrimaryClosureNotice {
        return PrimaryClosureNotice(
            code: code,
            title: title,
            approved: false,
            visible: false,
            limit: 0,
            budget: 0.0,
            status: PrimaryClosureNoticeStatus.draft
        )
    }
}
