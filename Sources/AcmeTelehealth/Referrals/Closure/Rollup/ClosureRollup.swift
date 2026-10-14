import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure rollup is in its life cycle.
    enum ClosureRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A closure rollup. Its code is unique within a tenant.
    final class ClosureRollup {
        var code: String
        var name: String
        var budget: Double
        var attempts: Int
        var tags: [String]
        var status: ClosureRollupStatus

        init(code: String, name: String, budget: Double, attempts: Int, tags: [String], status: ClosureRollupStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.attempts = attempts
            self.tags = tags
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

        func canMoveTo(_ next: ClosureRollupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ClosureRollupStatus.reopened
            case .inReview:
                return next == ClosureRollupStatus.resolved || next == ClosureRollupStatus.archived
            case .resolved:
                return next == ClosureRollupStatus.reopened || next == ClosureRollupStatus.archived
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

        func moveTo(_ next: ClosureRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((Double(attempts) - budget) * 100).rounded() / 100
        }

        func copyValue() -> ClosureRollup {
            return ClosureRollup(
                code: code,
                name: name,
                budget: budget,
                attempts: attempts,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a closure rollup in status open.
    static func newClosureRollup(_ code: String, name: String) -> ClosureRollup {
        return ClosureRollup(
            code: code,
            name: name,
            budget: 0.0,
            attempts: 0,
            tags: [],
            status: ClosureRollupStatus.`open`
        )
    }
}
