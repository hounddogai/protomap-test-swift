import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient dispense request is in its life cycle.
    enum LenientDispenseRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a lenient dispense request and its current status.
    final class LenientDispenseRequest {
        var code: String
        var label: String
        var ceiling: Double
        var title: String
        var capacity: Int
        var graceDays: Int
        var visible: Bool
        var status: LenientDispenseRequestStatus

        init(code: String, label: String, ceiling: Double, title: String, capacity: Int, graceDays: Int, visible: Bool, status: LenientDispenseRequestStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.title = title
            self.capacity = capacity
            self.graceDays = graceDays
            self.visible = visible
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

        func canMoveTo(_ next: LenientDispenseRequestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LenientDispenseRequestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDispenseRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient dispense request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((Double(capacity) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientDispenseRequest {
            return LenientDispenseRequest(
                code: code,
                label: label,
                ceiling: ceiling,
                title: title,
                capacity: capacity,
                graceDays: graceDays,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient dispense request in status idle.
    static func newLenientDispenseRequest(_ code: String, label: String) -> LenientDispenseRequest {
        return LenientDispenseRequest(
            code: code,
            label: label,
            ceiling: 0.0,
            title: "",
            capacity: 0,
            graceDays: 0,
            visible: false,
            status: LenientDispenseRequestStatus.idle
        )
    }
}
