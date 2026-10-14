import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift notice is in its life cycle.
    enum ShiftNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A shift notice. Its code is unique within a tenant.
    final class ShiftNotice {
        var code: String
        var label: String
        var timezone: String
        var category: String
        var externalRef: String
        var amount: Double
        var capacity: Int
        var status: ShiftNoticeStatus

        init(code: String, label: String, timezone: String, category: String, externalRef: String, amount: Double, capacity: Int, status: ShiftNoticeStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.category = category
            self.externalRef = externalRef
            self.amount = amount
            self.capacity = capacity
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

        func canMoveTo(_ next: ShiftNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == ShiftNoticeStatus.warming
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ShiftNoticeStatus.stopped
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

        func moveTo(_ next: ShiftNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return (amount * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> ShiftNotice {
            return ShiftNotice(
                code: code,
                label: label,
                timezone: timezone,
                category: category,
                externalRef: externalRef,
                amount: amount,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a shift notice in status idle.
    static func newShiftNotice(_ code: String, label: String) -> ShiftNotice {
        return ShiftNotice(
            code: code,
            label: label,
            timezone: "",
            category: "",
            externalRef: "",
            amount: 0.0,
            capacity: 0,
            status: ShiftNoticeStatus.idle
        )
    }
}
