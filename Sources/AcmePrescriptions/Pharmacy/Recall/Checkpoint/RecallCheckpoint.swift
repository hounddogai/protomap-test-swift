import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall checkpoint is in its life cycle.
    enum RecallCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A recall checkpoint as the recall team keeps it.
    final class RecallCheckpoint {
        var code: String
        var title: String
        var endsAt: Int
        var updatedAt: Int
        var name: String
        var rate: Double
        var batchSize: Int
        var capacity: Int
        var currency: String
        var status: RecallCheckpointStatus

        init(code: String, title: String, endsAt: Int, updatedAt: Int, name: String, rate: Double, batchSize: Int, capacity: Int, currency: String, status: RecallCheckpointStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.name = name
            self.rate = rate
            self.batchSize = batchSize
            self.capacity = capacity
            self.currency = currency
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

        func canMoveTo(_ next: RecallCheckpointStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RecallCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("recall checkpoint") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(batchSize) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> RecallCheckpoint {
            return RecallCheckpoint(
                code: code,
                title: title,
                endsAt: endsAt,
                updatedAt: updatedAt,
                name: name,
                rate: rate,
                batchSize: batchSize,
                capacity: capacity,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall checkpoint in status created.
    static func newRecallCheckpoint(_ code: String, title: String) -> RecallCheckpoint {
        return RecallCheckpoint(
            code: code,
            title: title,
            endsAt: 0,
            updatedAt: 0,
            name: "",
            rate: 0.0,
            batchSize: 0,
            capacity: 0,
            currency: "",
            status: RecallCheckpointStatus.created
        )
    }
}
