import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance batch is in its life cycle.
    enum RemittanceBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One remittance batch, with what the planners need to act on it.
    final class RemittanceBatch {
        var code: String
        var name: String
        var pinned: Bool
        var notes: String
        var quantity: Int
        var margin: Double
        var status: RemittanceBatchStatus

        init(code: String, name: String, pinned: Bool, notes: String, quantity: Int, margin: Double, status: RemittanceBatchStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.notes = notes
            self.quantity = quantity
            self.margin = margin
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

        func canMoveTo(_ next: RemittanceBatchStatus) -> Bool {
            switch status {
            case .idle:
                return next == RemittanceBatchStatus.warming
            case .warming:
                return next == RemittanceBatchStatus.draining
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RemittanceBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return (Double(quantity) * margin * 100).rounded() / 100
        }

        func copyValue() -> RemittanceBatch {
            return RemittanceBatch(
                code: code,
                name: name,
                pinned: pinned,
                notes: notes,
                quantity: quantity,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance batch in status idle.
    static func newRemittanceBatch(_ code: String, name: String) -> RemittanceBatch {
        return RemittanceBatch(
            code: code,
            name: name,
            pinned: false,
            notes: "",
            quantity: 0,
            margin: 0.0,
            status: RemittanceBatchStatus.idle
        )
    }
}
