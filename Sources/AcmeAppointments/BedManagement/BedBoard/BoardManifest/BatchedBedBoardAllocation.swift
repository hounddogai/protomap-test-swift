import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched bed board allocation is in its life cycle.
    enum BatchedBedBoardAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched bed board allocation and its current status.
    final class BatchedBedBoardAllocation {
        var code: String
        var label: String
        var dosageMg: Double
        var description: String
        var category: String
        var tags: [String]
        var status: BatchedBedBoardAllocationStatus

        init(code: String, label: String, dosageMg: Double, description: String, category: String, tags: [String], status: BatchedBedBoardAllocationStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.description = description
            self.category = category
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedBedBoardAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedBedBoardAllocationStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedBedBoardAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedBedBoardAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched bed board allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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
            return dosageMg
        }

        func copyValue() -> BatchedBedBoardAllocation {
            return BatchedBedBoardAllocation(
                code: code,
                label: label,
                dosageMg: dosageMg,
                description: description,
                category: category,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched bed board allocation in status new.
    static func newBatchedBedBoardAllocation(_ code: String, label: String) -> BatchedBedBoardAllocation {
        return BatchedBedBoardAllocation(
            code: code,
            label: label,
            dosageMg: 0.0,
            description: "",
            category: "",
            tags: [],
            status: BatchedBedBoardAllocationStatus.new
        )
    }
}
