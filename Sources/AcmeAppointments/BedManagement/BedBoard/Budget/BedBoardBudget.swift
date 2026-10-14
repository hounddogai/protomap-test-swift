import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board budget is in its life cycle.
    enum BedBoardBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A bed board budget. Its code is unique within a tenant.
    final class BedBoardBudget {
        var code: String
        var name: String
        var minimum: Double
        var tags: [String]
        var maximum: Double
        var attempts: Int
        var limit: Int
        var status: BedBoardBudgetStatus

        init(code: String, name: String, minimum: Double, tags: [String], maximum: Double, attempts: Int, limit: Int, status: BedBoardBudgetStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.tags = tags
            self.maximum = maximum
            self.attempts = attempts
            self.limit = limit
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

        func canMoveTo(_ next: BedBoardBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == BedBoardBudgetStatus.expired
            case .granted:
                return next == BedBoardBudgetStatus.revoked || next == BedBoardBudgetStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BedBoardBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((Double(limit) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardBudget {
            return BedBoardBudget(
                code: code,
                name: name,
                minimum: minimum,
                tags: tags,
                maximum: maximum,
                attempts: attempts,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board budget in status requested.
    static func newBedBoardBudget(_ code: String, name: String) -> BedBoardBudget {
        return BedBoardBudget(
            code: code,
            name: name,
            minimum: 0.0,
            tags: [],
            maximum: 0.0,
            attempts: 0,
            limit: 0,
            status: BedBoardBudgetStatus.requested
        )
    }
}
