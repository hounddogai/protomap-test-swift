import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional modality batch is in its life cycle.
    enum RegionalModalityBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional modality batch and its current status.
    final class RegionalModalityBatch {
        var code: String
        var label: String
        var priority: Int
        var capacity: Int
        var quantity: Int
        var name: String
        var status: RegionalModalityBatchStatus

        init(code: String, label: String, priority: Int, capacity: Int, quantity: Int, name: String, status: RegionalModalityBatchStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.capacity = capacity
            self.quantity = quantity
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalModalityBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RegionalModalityBatchStatus.archived
            case .reopened:
                return next == RegionalModalityBatchStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalModalityBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional modality batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((Double(quantity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalModalityBatch {
            return RegionalModalityBatch(
                code: code,
                label: label,
                priority: priority,
                capacity: capacity,
                quantity: quantity,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional modality batch in status open.
    static func newRegionalModalityBatch(_ code: String, label: String) -> RegionalModalityBatch {
        return RegionalModalityBatch(
            code: code,
            label: label,
            priority: 0,
            capacity: 0,
            quantity: 0,
            name: "",
            status: RegionalModalityBatchStatus.`open`
        )
    }
}
