import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a tiered cleaning rule is in its life cycle.
    enum TieredCleaningRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered cleaning rule, with what the planners need to act on it.
    final class TieredCleaningRule {
        var code: String
        var name: String
        var amount: Double
        var limit: Int
        var version: Int
        var discount: Double
        var status: TieredCleaningRuleStatus

        init(code: String, name: String, amount: Double, limit: Int, version: Int, discount: Double, status: TieredCleaningRuleStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.limit = limit
            self.version = version
            self.discount = discount
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

        func canMoveTo(_ next: TieredCleaningRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == TieredCleaningRuleStatus.reopened || next == TieredCleaningRuleStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredCleaningRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered cleaning rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((discount + amount) * 100).rounded() / 100
        }

        func copyValue() -> TieredCleaningRule {
            return TieredCleaningRule(
                code: code,
                name: name,
                amount: amount,
                limit: limit,
                version: version,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered cleaning rule in status open.
    static func newTieredCleaningRule(_ code: String, name: String) -> TieredCleaningRule {
        return TieredCleaningRule(
            code: code,
            name: name,
            amount: 0.0,
            limit: 0,
            version: 0,
            discount: 0.0,
            status: TieredCleaningRuleStatus.`open`
        )
    }
}
