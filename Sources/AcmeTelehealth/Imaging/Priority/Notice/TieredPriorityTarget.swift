import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered priority target is in its life cycle.
    enum TieredPriorityTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered priority target. Its code is unique within a tenant.
    final class TieredPriorityTarget {
        var code: String
        var name: String
        var description: String
        var amount: Double
        var endsAt: Int
        var status: TieredPriorityTargetStatus

        init(code: String, name: String, description: String, amount: Double, endsAt: Int, status: TieredPriorityTargetStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.amount = amount
            self.endsAt = endsAt
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

        func canMoveTo(_ next: TieredPriorityTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
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
                return next == TieredPriorityTargetStatus.closed
            case .suspended:
                return next == TieredPriorityTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredPriorityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered priority target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered priority target") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(endsAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> TieredPriorityTarget {
            return TieredPriorityTarget(
                code: code,
                name: name,
                description: description,
                amount: amount,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered priority target in status draft.
    static func newTieredPriorityTarget(_ code: String, name: String) -> TieredPriorityTarget {
        return TieredPriorityTarget(
            code: code,
            name: name,
            description: "",
            amount: 0.0,
            endsAt: 0,
            status: TieredPriorityTargetStatus.draft
        )
    }
}
