import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier slot is in its life cycle.
    enum DefaultCourierSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default courier slot as the courier team keeps it.
    final class DefaultCourierSlot {
        var code: String
        var name: String
        var capacity: Int
        var amount: Double
        var durationMinutes: Int
        var visible: Bool
        var startsAt: Int
        var budget: Double
        var windowDays: Int
        var status: DefaultCourierSlotStatus

        init(code: String, name: String, capacity: Int, amount: Double, durationMinutes: Int, visible: Bool, startsAt: Int, budget: Double, windowDays: Int, status: DefaultCourierSlotStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.amount = amount
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.startsAt = startsAt
            self.budget = budget
            self.windowDays = windowDays
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

        func canMoveTo(_ next: DefaultCourierSlotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultCourierSlotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCourierSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedTotal() -> Double {
            return (Double(windowDays) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCourierSlot {
            return DefaultCourierSlot(
                code: code,
                name: name,
                capacity: capacity,
                amount: amount,
                durationMinutes: durationMinutes,
                visible: visible,
                startsAt: startsAt,
                budget: budget,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default courier slot in status created.
    static func newDefaultCourierSlot(_ code: String, name: String) -> DefaultCourierSlot {
        return DefaultCourierSlot(
            code: code,
            name: name,
            capacity: 0,
            amount: 0.0,
            durationMinutes: 0,
            visible: false,
            startsAt: 0,
            budget: 0.0,
            windowDays: 0,
            status: DefaultCourierSlotStatus.created
        )
    }
}
