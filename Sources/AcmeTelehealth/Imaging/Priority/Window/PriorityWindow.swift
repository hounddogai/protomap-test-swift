import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority window is in its life cycle.
    enum PriorityWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a priority window and its current status.
    final class PriorityWindow {
        var code: String
        var name: String
        var reviewer: String
        var amount: Double
        var locale: String
        var pinned: Bool
        var title: String
        var status: PriorityWindowStatus

        init(code: String, name: String, reviewer: String, amount: Double, locale: String, pinned: Bool, title: String, status: PriorityWindowStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.amount = amount
            self.locale = locale
            self.pinned = pinned
            self.title = title
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

        func canMoveTo(_ next: PriorityWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PriorityWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> PriorityWindow {
            return PriorityWindow(
                code: code,
                name: name,
                reviewer: reviewer,
                amount: amount,
                locale: locale,
                pinned: pinned,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a priority window in status created.
    static func newPriorityWindow(_ code: String, name: String) -> PriorityWindow {
        return PriorityWindow(
            code: code,
            name: name,
            reviewer: "",
            amount: 0.0,
            locale: "",
            pinned: false,
            title: "",
            status: PriorityWindowStatus.created
        )
    }
}
