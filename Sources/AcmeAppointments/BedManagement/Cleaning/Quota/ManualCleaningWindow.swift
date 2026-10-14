import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual cleaning window is in its life cycle.
    enum ManualCleaningWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual cleaning window as the cleaning team keeps it.
    final class ManualCleaningWindow {
        var code: String
        var label: String
        var phone: String
        var attempts: Int
        var limit: Int
        var status: ManualCleaningWindowStatus

        init(code: String, label: String, phone: String, attempts: Int, limit: Int, status: ManualCleaningWindowStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.attempts = attempts
            self.limit = limit
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

        func canMoveTo(_ next: ManualCleaningWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ManualCleaningWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCleaningWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual cleaning window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual cleaning window") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(limit) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> ManualCleaningWindow {
            return ManualCleaningWindow(
                code: code,
                label: label,
                phone: phone,
                attempts: attempts,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual cleaning window in status idle.
    static func newManualCleaningWindow(_ code: String, label: String) -> ManualCleaningWindow {
        return ManualCleaningWindow(
            code: code,
            label: label,
            phone: "",
            attempts: 0,
            limit: 0,
            status: ManualCleaningWindowStatus.idle
        )
    }
}
