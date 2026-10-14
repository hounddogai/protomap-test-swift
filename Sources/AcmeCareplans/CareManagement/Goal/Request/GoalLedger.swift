import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal ledger is in its life cycle.
    enum GoalLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A goal ledger as the goal team keeps it.
    final class GoalLedger {
        var code: String
        var name: String
        var checksum: String
        var updatedAt: Int
        var cost: Double
        var weight: Double
        var ward: String
        var locale: String
        var ratio: Double
        var status: GoalLedgerStatus

        init(code: String, name: String, checksum: String, updatedAt: Int, cost: Double, weight: Double, ward: String, locale: String, ratio: Double, status: GoalLedgerStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.updatedAt = updatedAt
            self.cost = cost
            self.weight = weight
            self.ward = ward
            self.locale = locale
            self.ratio = ratio
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

        func canMoveTo(_ next: GoalLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GoalLedgerStatus.archived
            case .resolved:
                return next == GoalLedgerStatus.reopened || next == GoalLedgerStatus.archived
            case .reopened:
                return next == GoalLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return (weight * cost * 100).rounded() / 100
        }

        func copyValue() -> GoalLedger {
            return GoalLedger(
                code: code,
                name: name,
                checksum: checksum,
                updatedAt: updatedAt,
                cost: cost,
                weight: weight,
                ward: ward,
                locale: locale,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a goal ledger in status open.
    static func newGoalLedger(_ code: String, name: String) -> GoalLedger {
        return GoalLedger(
            code: code,
            name: name,
            checksum: "",
            updatedAt: 0,
            cost: 0.0,
            weight: 0.0,
            ward: "",
            locale: "",
            ratio: 0.0,
            status: GoalLedgerStatus.`open`
        )
    }
}
