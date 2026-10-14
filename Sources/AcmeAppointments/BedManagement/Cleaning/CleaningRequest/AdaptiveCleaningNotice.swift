import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive cleaning notice is in its life cycle.
    enum AdaptiveCleaningNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive cleaning notice as the cleaning team keeps it.
    final class AdaptiveCleaningNotice {
        var code: String
        var title: String
        var capacity: Int
        var pinned: Bool
        var graceDays: Int
        var ceiling: Double
        var bed: String
        var visitMinutes: Int
        var priority: Int
        var quantity: Int
        var budget: Double
        var status: AdaptiveCleaningNoticeStatus

        init(code: String, title: String, capacity: Int, pinned: Bool, graceDays: Int, ceiling: Double, bed: String, visitMinutes: Int, priority: Int, quantity: Int, budget: Double, status: AdaptiveCleaningNoticeStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.pinned = pinned
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.bed = bed
            self.visitMinutes = visitMinutes
            self.priority = priority
            self.quantity = quantity
            self.budget = budget
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

        func canMoveTo(_ next: AdaptiveCleaningNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AdaptiveCleaningNoticeStatus.revoked
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

        func moveTo(_ next: AdaptiveCleaningNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive cleaning notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive cleaning notice") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(priority) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCleaningNotice {
            return AdaptiveCleaningNotice(
                code: code,
                title: title,
                capacity: capacity,
                pinned: pinned,
                graceDays: graceDays,
                ceiling: ceiling,
                bed: bed,
                visitMinutes: visitMinutes,
                priority: priority,
                quantity: quantity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive cleaning notice in status requested.
    static func newAdaptiveCleaningNotice(_ code: String, title: String) -> AdaptiveCleaningNotice {
        return AdaptiveCleaningNotice(
            code: code,
            title: title,
            capacity: 0,
            pinned: false,
            graceDays: 0,
            ceiling: 0.0,
            bed: "",
            visitMinutes: 0,
            priority: 0,
            quantity: 0,
            budget: 0.0,
            status: AdaptiveCleaningNoticeStatus.requested
        )
    }
}
