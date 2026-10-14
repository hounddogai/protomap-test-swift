import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure snapshot is in its life cycle.
    enum ClosureSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a closure snapshot and its current status.
    final class ClosureSnapshot {
        var code: String
        var title: String
        var unit: String
        var locale: String
        var country: String
        var pinned: Bool
        var notes: String
        var score: Double
        var status: ClosureSnapshotStatus

        init(code: String, title: String, unit: String, locale: String, country: String, pinned: Bool, notes: String, score: Double, status: ClosureSnapshotStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.locale = locale
            self.country = country
            self.pinned = pinned
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

        func canMoveTo(_ next: ClosureSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == ClosureSnapshotStatus.inProgress || next == ClosureSnapshotStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
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

        func moveTo(_ next: ClosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("closure snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ClosureSnapshot {
            return ClosureSnapshot(
                code: code,
                title: title,
                unit: unit,
                locale: locale,
                country: country,
                pinned: pinned,
                notes: notes,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a closure snapshot in status planned.
    static func newClosureSnapshot(_ code: String, title: String) -> ClosureSnapshot {
        return ClosureSnapshot(
            code: code,
            title: title,
            unit: "",
            locale: "",
            country: "",
            pinned: false,
            notes: "",
            score: 0.0,
            status: ClosureSnapshotStatus.planned
        )
    }
}
