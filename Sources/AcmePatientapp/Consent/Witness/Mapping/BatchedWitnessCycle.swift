import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness cycle is in its life cycle.
    enum BatchedWitnessCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched witness cycle and its current status.
    final class BatchedWitnessCycle {
        var code: String
        var name: String
        var label: String
        var pinned: Bool
        var externalRef: String
        var budget: Double
        var status: BatchedWitnessCycleStatus

        init(code: String, name: String, label: String, pinned: Bool, externalRef: String, budget: Double, status: BatchedWitnessCycleStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.pinned = pinned
            self.externalRef = externalRef
            self.budget = budget
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

        func canMoveTo(_ next: BatchedWitnessCycleStatus) -> Bool {
            switch status {
            case .new:
                return next == BatchedWitnessCycleStatus.queued
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedWitnessCycleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedWitnessCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched witness cycle") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> BatchedWitnessCycle {
            return BatchedWitnessCycle(
                code: code,
                name: name,
                label: label,
                pinned: pinned,
                externalRef: externalRef,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched witness cycle in status new.
    static func newBatchedWitnessCycle(_ code: String, name: String) -> BatchedWitnessCycle {
        return BatchedWitnessCycle(
            code: code,
            name: name,
            label: "",
            pinned: false,
            externalRef: "",
            budget: 0.0,
            status: BatchedWitnessCycleStatus.new
        )
    }
}
