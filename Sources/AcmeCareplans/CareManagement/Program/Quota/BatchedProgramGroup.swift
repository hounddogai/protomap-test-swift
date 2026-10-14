import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched program group is in its life cycle.
    enum BatchedProgramGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One batched program group, with what the planners need to act on it.
    final class BatchedProgramGroup {
        var code: String
        var label: String
        var maximum: Double
        var procedureCode: String
        var limit: Int
        var status: BatchedProgramGroupStatus

        init(code: String, label: String, maximum: Double, procedureCode: String, limit: Int, status: BatchedProgramGroupStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.procedureCode = procedureCode
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedProgramGroupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedProgramGroupStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: BatchedProgramGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched program group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched program group") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(limit) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProgramGroup {
            return BatchedProgramGroup(
                code: code,
                label: label,
                maximum: maximum,
                procedureCode: procedureCode,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched program group in status draft.
    static func newBatchedProgramGroup(_ code: String, label: String) -> BatchedProgramGroup {
        return BatchedProgramGroup(
            code: code,
            label: label,
            maximum: 0.0,
            procedureCode: "",
            limit: 0,
            status: BatchedProgramGroupStatus.draft
        )
    }
}
