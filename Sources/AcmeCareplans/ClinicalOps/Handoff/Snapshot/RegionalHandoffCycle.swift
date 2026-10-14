import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional handoff cycle is in its life cycle.
    enum RegionalHandoffCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional handoff cycle and its current status.
    final class RegionalHandoffCycle {
        var code: String
        var title: String
        var createdAt: Int
        var maximum: Double
        var amount: Double
        var status: RegionalHandoffCycleStatus

        init(code: String, title: String, createdAt: Int, maximum: Double, amount: Double, status: RegionalHandoffCycleStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.maximum = maximum
            self.amount = amount
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

        func canMoveTo(_ next: RegionalHandoffCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalHandoffCycleStatus.resolved
            case .inReview:
                return next == RegionalHandoffCycleStatus.resolved
            case .resolved:
                return next == RegionalHandoffCycleStatus.reopened || next == RegionalHandoffCycleStatus.archived
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

        func moveTo(_ next: RegionalHandoffCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional handoff cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((Double(createdAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalHandoffCycle {
            return RegionalHandoffCycle(
                code: code,
                title: title,
                createdAt: createdAt,
                maximum: maximum,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional handoff cycle in status open.
    static func newRegionalHandoffCycle(_ code: String, title: String) -> RegionalHandoffCycle {
        return RegionalHandoffCycle(
            code: code,
            title: title,
            createdAt: 0,
            maximum: 0.0,
            amount: 0.0,
            status: RegionalHandoffCycleStatus.`open`
        )
    }
}
