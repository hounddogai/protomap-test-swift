import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched isolation window is in its life cycle.
    enum BatchedIsolationWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched isolation window. Its code is unique within a tenant.
    final class BatchedIsolationWindow {
        var code: String
        var label: String
        var notes: String
        var facility: String
        var currency: String
        var quantity: Int
        var status: BatchedIsolationWindowStatus

        init(code: String, label: String, notes: String, facility: String, currency: String, quantity: Int, status: BatchedIsolationWindowStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.facility = facility
            self.currency = currency
            self.quantity = quantity
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

        func canMoveTo(_ next: BatchedIsolationWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedIsolationWindowStatus.ready
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
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: BatchedIsolationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched isolation window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> BatchedIsolationWindow {
            return BatchedIsolationWindow(
                code: code,
                label: label,
                notes: notes,
                facility: facility,
                currency: currency,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched isolation window in status idle.
    static func newBatchedIsolationWindow(_ code: String, label: String) -> BatchedIsolationWindow {
        return BatchedIsolationWindow(
            code: code,
            label: label,
            notes: "",
            facility: "",
            currency: "",
            quantity: 0,
            status: BatchedIsolationWindowStatus.idle
        )
    }
}
