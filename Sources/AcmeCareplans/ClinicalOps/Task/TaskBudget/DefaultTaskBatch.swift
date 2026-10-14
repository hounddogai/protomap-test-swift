import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default task batch is in its life cycle.
    enum DefaultTaskBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default task batch and its current status.
    final class DefaultTaskBatch {
        var code: String
        var title: String
        var ownerID: String
        var currency: String
        var weight: Double
        var facility: String
        var category: String
        var channel: String
        var graceDays: Int
        var status: DefaultTaskBatchStatus

        init(code: String, title: String, ownerID: String, currency: String, weight: Double, facility: String, category: String, channel: String, graceDays: Int, status: DefaultTaskBatchStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.currency = currency
            self.weight = weight
            self.facility = facility
            self.category = category
            self.channel = channel
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultTaskBatchStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultTaskBatchStatus.inProgress || next == DefaultTaskBatchStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DefaultTaskBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default task batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return (weight * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> DefaultTaskBatch {
            return DefaultTaskBatch(
                code: code,
                title: title,
                ownerID: ownerID,
                currency: currency,
                weight: weight,
                facility: facility,
                category: category,
                channel: channel,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default task batch in status planned.
    static func newDefaultTaskBatch(_ code: String, title: String) -> DefaultTaskBatch {
        return DefaultTaskBatch(
            code: code,
            title: title,
            ownerID: "",
            currency: "",
            weight: 0.0,
            facility: "",
            category: "",
            channel: "",
            graceDays: 0,
            status: DefaultTaskBatchStatus.planned
        )
    }
}
