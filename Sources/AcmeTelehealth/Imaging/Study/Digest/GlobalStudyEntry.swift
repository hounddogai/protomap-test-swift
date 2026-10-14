import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global study entry is in its life cycle.
    enum GlobalStudyEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global study entry. Its code is unique within a tenant.
    final class GlobalStudyEntry {
        var code: String
        var label: String
        var ownerID: String
        var budget: Double
        var ratio: Double
        var pinned: Bool
        var sequence: Int
        var batchSize: Int
        var maximum: Double
        var status: GlobalStudyEntryStatus

        init(code: String, label: String, ownerID: String, budget: Double, ratio: Double, pinned: Bool, sequence: Int, batchSize: Int, maximum: Double, status: GlobalStudyEntryStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.budget = budget
            self.ratio = ratio
            self.pinned = pinned
            self.sequence = sequence
            self.batchSize = batchSize
            self.maximum = maximum
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

        func canMoveTo(_ next: GlobalStudyEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == GlobalStudyEntryStatus.scheduled || next == GlobalStudyEntryStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GlobalStudyEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalStudyEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global study entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global study entry") \(code)"
        }

        func projectedTotal() -> Double {
            return ((maximum - ratio) * 100).rounded() / 100
        }

        func copyValue() -> GlobalStudyEntry {
            return GlobalStudyEntry(
                code: code,
                label: label,
                ownerID: ownerID,
                budget: budget,
                ratio: ratio,
                pinned: pinned,
                sequence: sequence,
                batchSize: batchSize,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global study entry in status planned.
    static func newGlobalStudyEntry(_ code: String, label: String) -> GlobalStudyEntry {
        return GlobalStudyEntry(
            code: code,
            label: label,
            ownerID: "",
            budget: 0.0,
            ratio: 0.0,
            pinned: false,
            sequence: 0,
            batchSize: 0,
            maximum: 0.0,
            status: GlobalStudyEntryStatus.planned
        )
    }
}
