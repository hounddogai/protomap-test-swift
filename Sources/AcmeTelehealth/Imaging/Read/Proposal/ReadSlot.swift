import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read slot is in its life cycle.
    enum ReadSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One read slot, with what the planners need to act on it.
    final class ReadSlot {
        var code: String
        var label: String
        var retries: Int
        var startsAt: Int
        var pinned: Bool
        var copay: Double
        var graceDays: Int
        var status: ReadSlotStatus

        init(code: String, label: String, retries: Int, startsAt: Int, pinned: Bool, copay: Double, graceDays: Int, status: ReadSlotStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.startsAt = startsAt
            self.pinned = pinned
            self.copay = copay
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ReadSlotStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReadSlotStatus.warming || next == ReadSlotStatus.stopped
            case .warming:
                return next == ReadSlotStatus.ready || next == ReadSlotStatus.draining
            case .ready:
                return next == ReadSlotStatus.stopped
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

        func moveTo(_ next: ReadSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(graceDays) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ReadSlot {
            return ReadSlot(
                code: code,
                label: label,
                retries: retries,
                startsAt: startsAt,
                pinned: pinned,
                copay: copay,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read slot in status idle.
    static func newReadSlot(_ code: String, label: String) -> ReadSlot {
        return ReadSlot(
            code: code,
            label: label,
            retries: 0,
            startsAt: 0,
            pinned: false,
            copay: 0.0,
            graceDays: 0,
            status: ReadSlotStatus.idle
        )
    }
}
