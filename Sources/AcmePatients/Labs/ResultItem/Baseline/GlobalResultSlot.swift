import AcmePlatform
import Foundation

extension Labs {
    /// Where a global result slot is in its life cycle.
    enum GlobalResultSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global result slot, with what the planners need to act on it.
    final class GlobalResultSlot {
        var code: String
        var name: String
        var payer: String
        var maximum: Double
        var externalRef: String
        var notes: String
        var ceiling: Double
        var status: GlobalResultSlotStatus

        init(code: String, name: String, payer: String, maximum: Double, externalRef: String, notes: String, ceiling: Double, status: GlobalResultSlotStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.maximum = maximum
            self.externalRef = externalRef
            self.notes = notes
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalResultSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalResultSlotStatus.ready || next == GlobalResultSlotStatus.draining
            case .ready:
                return next == GlobalResultSlotStatus.draining || next == GlobalResultSlotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalResultSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global result slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global result slot") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((ceiling + maximum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalResultSlot {
            return GlobalResultSlot(
                code: code,
                name: name,
                payer: payer,
                maximum: maximum,
                externalRef: externalRef,
                notes: notes,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global result slot in status idle.
    static func newGlobalResultSlot(_ code: String, name: String) -> GlobalResultSlot {
        return GlobalResultSlot(
            code: code,
            name: name,
            payer: "",
            maximum: 0.0,
            externalRef: "",
            notes: "",
            ceiling: 0.0,
            status: GlobalResultSlotStatus.idle
        )
    }
}
