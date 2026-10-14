import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot summary is in its life cycle.
    enum SlotSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A slot summary as the slot team keeps it.
    final class SlotSummary {
        var code: String
        var title: String
        var priority: Int
        var visible: Bool
        var category: String
        var status: SlotSummaryStatus

        init(code: String, title: String, priority: Int, visible: Bool, category: String, status: SlotSummaryStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.visible = visible
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == SlotSummaryStatus.published || next == SlotSummaryStatus.retired
            case .validated:
                return next == SlotSummaryStatus.published || next == SlotSummaryStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SlotSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot summary") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> SlotSummary {
            return SlotSummary(
                code: code,
                title: title,
                priority: priority,
                visible: visible,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a slot summary in status created.
    static func newSlotSummary(_ code: String, title: String) -> SlotSummary {
        return SlotSummary(
            code: code,
            title: title,
            priority: 0,
            visible: false,
            category: "",
            status: SlotSummaryStatus.created
        )
    }
}
