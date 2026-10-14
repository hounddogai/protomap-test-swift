import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality snapshot is in its life cycle.
    enum ModalitySnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A modality snapshot as the modality team keeps it.
    final class ModalitySnapshot {
        var code: String
        var title: String
        var budget: Double
        var cost: Double
        var durationMinutes: Int
        var status: ModalitySnapshotStatus

        init(code: String, title: String, budget: Double, cost: Double, durationMinutes: Int, status: ModalitySnapshotStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.cost = cost
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ModalitySnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == ModalitySnapshotStatus.pending
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ModalitySnapshotStatus.closed
            case .suspended:
                return next == ModalitySnapshotStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalitySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("modality snapshot") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(durationMinutes) + budget) * 100).rounded() / 100
        }

        func copyValue() -> ModalitySnapshot {
            return ModalitySnapshot(
                code: code,
                title: title,
                budget: budget,
                cost: cost,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a modality snapshot in status draft.
    static func newModalitySnapshot(_ code: String, title: String) -> ModalitySnapshot {
        return ModalitySnapshot(
            code: code,
            title: title,
            budget: 0.0,
            cost: 0.0,
            durationMinutes: 0,
            status: ModalitySnapshotStatus.draft
        )
    }
}
