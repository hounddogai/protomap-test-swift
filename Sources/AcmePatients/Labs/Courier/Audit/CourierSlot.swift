import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier slot is in its life cycle.
    enum CourierSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a courier slot and its current status.
    final class CourierSlot {
        var code: String
        var name: String
        var segment: String
        var durationMinutes: Int
        var unit: String
        var quantity: Int
        var capacity: Int
        var status: CourierSlotStatus

        init(code: String, name: String, segment: String, durationMinutes: Int, unit: String, quantity: Int, capacity: Int, status: CourierSlotStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.quantity = quantity
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == CourierSlotStatus.done || next == CourierSlotStatus.failed
            case .queued:
                return next == CourierSlotStatus.running || next == CourierSlotStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CourierSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return (Double(quantity) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> CourierSlot {
            return CourierSlot(
                code: code,
                name: name,
                segment: segment,
                durationMinutes: durationMinutes,
                unit: unit,
                quantity: quantity,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a courier slot in status new.
    static func newCourierSlot(_ code: String, name: String) -> CourierSlot {
        return CourierSlot(
            code: code,
            name: name,
            segment: "",
            durationMinutes: 0,
            unit: "",
            quantity: 0,
            capacity: 0,
            status: CourierSlotStatus.new
        )
    }
}
