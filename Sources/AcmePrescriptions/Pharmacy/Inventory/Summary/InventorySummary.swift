import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory summary is in its life cycle.
    enum InventorySummaryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One inventory summary, with what the planners need to act on it.
    final class InventorySummary {
        var code: String
        var name: String
        var archived: Bool
        var approved: Bool
        var quantity: Int
        var endsAt: Int
        var threshold: Double
        var status: InventorySummaryStatus

        init(code: String, name: String, archived: Bool, approved: Bool, quantity: Int, endsAt: Int, threshold: Double, status: InventorySummaryStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.approved = approved
            self.quantity = quantity
            self.endsAt = endsAt
            self.threshold = threshold
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

        func canMoveTo(_ next: InventorySummaryStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InventorySummaryStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == InventorySummaryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventorySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("inventory summary") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> InventorySummary {
            return InventorySummary(
                code: code,
                name: name,
                archived: archived,
                approved: approved,
                quantity: quantity,
                endsAt: endsAt,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a inventory summary in status open.
    static func newInventorySummary(_ code: String, name: String) -> InventorySummary {
        return InventorySummary(
            code: code,
            name: name,
            archived: false,
            approved: false,
            quantity: 0,
            endsAt: 0,
            threshold: 0.0,
            status: InventorySummaryStatus.`open`
        )
    }
}
