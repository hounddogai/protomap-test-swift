import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered modality window is in its life cycle.
    enum TieredModalityWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered modality window as the modality team keeps it.
    final class TieredModalityWindow {
        var code: String
        var title: String
        var specialty: String
        var unit: String
        var notes: String
        var score: Double
        var status: TieredModalityWindowStatus

        init(code: String, title: String, specialty: String, unit: String, notes: String, score: Double, status: TieredModalityWindowStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.unit = unit
            self.notes = notes
            self.score = score
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

        func canMoveTo(_ next: TieredModalityWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredModalityWindowStatus.scheduled
            case .scheduled:
                return next == TieredModalityWindowStatus.inProgress || next == TieredModalityWindowStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredModalityWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered modality window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> TieredModalityWindow {
            return TieredModalityWindow(
                code: code,
                title: title,
                specialty: specialty,
                unit: unit,
                notes: notes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a tiered modality window in status planned.
    static func newTieredModalityWindow(_ code: String, title: String) -> TieredModalityWindow {
        return TieredModalityWindow(
            code: code,
            title: title,
            specialty: "",
            unit: "",
            notes: "",
            score: 0.0,
            status: TieredModalityWindowStatus.planned
        )
    }
}
