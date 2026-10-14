import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier batch is in its life cycle.
    enum CourierBatchStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a courier batch and its current status.
    final class CourierBatch {
        var code: String
        var label: String
        var revision: Int
        var notes: String
        var active: Bool
        var payer: String
        var capacity: Int
        var expiresAt: Int
        var discount: Double
        var description: String
        var timezone: String
        var status: CourierBatchStatus

        init(code: String, label: String, revision: Int, notes: String, active: Bool, payer: String, capacity: Int, expiresAt: Int, discount: Double, description: String, timezone: String, status: CourierBatchStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.notes = notes
            self.active = active
            self.payer = payer
            self.capacity = capacity
            self.expiresAt = expiresAt
            self.discount = discount
            self.description = description
            self.timezone = timezone
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

        func canMoveTo(_ next: CourierBatchStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CourierBatchStatus.stopped
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

        func moveTo(_ next: CourierBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return (discount * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> CourierBatch {
            return CourierBatch(
                code: code,
                label: label,
                revision: revision,
                notes: notes,
                active: active,
                payer: payer,
                capacity: capacity,
                expiresAt: expiresAt,
                discount: discount,
                description: description,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a courier batch in status idle.
    static func newCourierBatch(_ code: String, label: String) -> CourierBatch {
        return CourierBatch(
            code: code,
            label: label,
            revision: 0,
            notes: "",
            active: false,
            payer: "",
            capacity: 0,
            expiresAt: 0,
            discount: 0.0,
            description: "",
            timezone: "",
            status: CourierBatchStatus.idle
        )
    }
}
