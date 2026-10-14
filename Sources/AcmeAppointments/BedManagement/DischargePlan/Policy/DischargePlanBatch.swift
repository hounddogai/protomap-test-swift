import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan batch is in its life cycle.
    enum DischargePlanBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A discharge plan batch as the discharge plan team keeps it.
    final class DischargePlanBatch {
        var code: String
        var label: String
        var sequence: Int
        var description: String
        var tags: [String]
        var status: DischargePlanBatchStatus

        init(code: String, label: String, sequence: Int, description: String, tags: [String], status: DischargePlanBatchStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.description = description
            self.tags = tags
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

        func canMoveTo(_ next: DischargePlanBatchStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DischargePlanBatchStatus.inReview || next == DischargePlanBatchStatus.resolved
            case .inReview:
                return next == DischargePlanBatchStatus.resolved
            case .resolved:
                return next == DischargePlanBatchStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DischargePlanBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("discharge plan batch") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> DischargePlanBatch {
            return DischargePlanBatch(
                code: code,
                label: label,
                sequence: sequence,
                description: description,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a discharge plan batch in status open.
    static func newDischargePlanBatch(_ code: String, label: String) -> DischargePlanBatch {
        return DischargePlanBatch(
            code: code,
            label: label,
            sequence: 0,
            description: "",
            tags: [],
            status: DischargePlanBatchStatus.`open`
        )
    }
}
