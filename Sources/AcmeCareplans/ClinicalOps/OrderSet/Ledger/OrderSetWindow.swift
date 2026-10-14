import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set window is in its life cycle.
    enum OrderSetWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One order set window, with what the planners need to act on it.
    final class OrderSetWindow {
        var code: String
        var title: String
        var reviewer: String
        var pinned: Bool
        var version: Int
        var budget: Double
        var updatedAt: Int
        var expiresAt: Int
        var status: OrderSetWindowStatus

        init(code: String, title: String, reviewer: String, pinned: Bool, version: Int, budget: Double, updatedAt: Int, expiresAt: Int, status: OrderSetWindowStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.pinned = pinned
            self.version = version
            self.budget = budget
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: OrderSetWindowStatus) -> Bool {
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
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == OrderSetWindowStatus.suspended || next == OrderSetWindowStatus.closed
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

        func moveTo(_ next: OrderSetWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return (Double(expiresAt) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetWindow {
            return OrderSetWindow(
                code: code,
                title: title,
                reviewer: reviewer,
                pinned: pinned,
                version: version,
                budget: budget,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set window in status draft.
    static func newOrderSetWindow(_ code: String, title: String) -> OrderSetWindow {
        return OrderSetWindow(
            code: code,
            title: title,
            reviewer: "",
            pinned: false,
            version: 0,
            budget: 0.0,
            updatedAt: 0,
            expiresAt: 0,
            status: OrderSetWindowStatus.draft
        )
    }
}
