import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range batch is in its life cycle.
    enum ReferenceRangeBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a reference range batch and its current status.
    final class ReferenceRangeBatch {
        var code: String
        var label: String
        var notes: String
        var priority: Int
        var windowDays: Int
        var ceiling: Double
        var capacity: Int
        var budget: Double
        var discount: Double
        var batchSize: Int
        var durationMinutes: Int
        var status: ReferenceRangeBatchStatus

        init(code: String, label: String, notes: String, priority: Int, windowDays: Int, ceiling: Double, capacity: Int, budget: Double, discount: Double, batchSize: Int, durationMinutes: Int, status: ReferenceRangeBatchStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.priority = priority
            self.windowDays = windowDays
            self.ceiling = ceiling
            self.capacity = capacity
            self.budget = budget
            self.discount = discount
            self.batchSize = batchSize
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ReferenceRangeBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ReferenceRangeBatchStatus.done || next == ReferenceRangeBatchStatus.failed
            case .running:
                return next == ReferenceRangeBatchStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ReferenceRangeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return (Double(durationMinutes) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeBatch {
            return ReferenceRangeBatch(
                code: code,
                label: label,
                notes: notes,
                priority: priority,
                windowDays: windowDays,
                ceiling: ceiling,
                capacity: capacity,
                budget: budget,
                discount: discount,
                batchSize: batchSize,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a reference range batch in status new.
    static func newReferenceRangeBatch(_ code: String, label: String) -> ReferenceRangeBatch {
        return ReferenceRangeBatch(
            code: code,
            label: label,
            notes: "",
            priority: 0,
            windowDays: 0,
            ceiling: 0.0,
            capacity: 0,
            budget: 0.0,
            discount: 0.0,
            batchSize: 0,
            durationMinutes: 0,
            status: ReferenceRangeBatchStatus.new
        )
    }
}
