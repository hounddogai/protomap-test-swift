import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict modality snapshot is in its life cycle.
    enum StrictModalitySnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict modality snapshot. Its code is unique within a tenant.
    final class StrictModalitySnapshot {
        var code: String
        var label: String
        var floorValue: Double
        var batchSize: Int
        var category: String
        var active: Bool
        var notes: String
        var score: Double
        var status: StrictModalitySnapshotStatus

        init(code: String, label: String, floorValue: Double, batchSize: Int, category: String, active: Bool, notes: String, score: Double, status: StrictModalitySnapshotStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.category = category
            self.active = active
            self.notes = notes
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictModalitySnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictModalitySnapshotStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictModalitySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict modality snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netTotal() -> Double {
            return ((score - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> StrictModalitySnapshot {
            return StrictModalitySnapshot(
                code: code,
                label: label,
                floorValue: floorValue,
                batchSize: batchSize,
                category: category,
                active: active,
                notes: notes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict modality snapshot in status proposed.
    static func newStrictModalitySnapshot(_ code: String, label: String) -> StrictModalitySnapshot {
        return StrictModalitySnapshot(
            code: code,
            label: label,
            floorValue: 0.0,
            batchSize: 0,
            category: "",
            active: false,
            notes: "",
            score: 0.0,
            status: StrictModalitySnapshotStatus.proposed
        )
    }
}
