import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment entry is in its life cycle.
    enum AssessmentEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One assessment entry, with what the planners need to act on it.
    final class AssessmentEntry {
        var code: String
        var title: String
        var graceDays: Int
        var updatedAt: Int
        var capacity: Int
        var label: String
        var endsAt: Int
        var floorValue: Double
        var score: Double
        var ward: String
        var archived: Bool
        var status: AssessmentEntryStatus

        init(code: String, title: String, graceDays: Int, updatedAt: Int, capacity: Int, label: String, endsAt: Int, floorValue: Double, score: Double, ward: String, archived: Bool, status: AssessmentEntryStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.label = label
            self.endsAt = endsAt
            self.floorValue = floorValue
            self.score = score
            self.ward = ward
            self.archived = archived
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

        func canMoveTo(_ next: AssessmentEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == AssessmentEntryStatus.inProgress || next == AssessmentEntryStatus.completed
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

        func moveTo(_ next: AssessmentEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("assessment entry") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((floorValue - score) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentEntry {
            return AssessmentEntry(
                code: code,
                title: title,
                graceDays: graceDays,
                updatedAt: updatedAt,
                capacity: capacity,
                label: label,
                endsAt: endsAt,
                floorValue: floorValue,
                score: score,
                ward: ward,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a assessment entry in status planned.
    static func newAssessmentEntry(_ code: String, title: String) -> AssessmentEntry {
        return AssessmentEntry(
            code: code,
            title: title,
            graceDays: 0,
            updatedAt: 0,
            capacity: 0,
            label: "",
            endsAt: 0,
            floorValue: 0.0,
            score: 0.0,
            ward: "",
            archived: false,
            status: AssessmentEntryStatus.planned
        )
    }
}
