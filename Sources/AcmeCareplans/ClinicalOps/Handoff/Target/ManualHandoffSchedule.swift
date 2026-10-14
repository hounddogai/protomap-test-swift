import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual handoff schedule is in its life cycle.
    enum ManualHandoffScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a manual handoff schedule and its current status.
    final class ManualHandoffSchedule {
        var code: String
        var label: String
        var bed: String
        var ownerID: String
        var score: Double
        var externalRef: String
        var updatedAt: Int
        var timezone: String
        var status: ManualHandoffScheduleStatus

        init(code: String, label: String, bed: String, ownerID: String, score: Double, externalRef: String, updatedAt: Int, timezone: String, status: ManualHandoffScheduleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.ownerID = ownerID
            self.score = score
            self.externalRef = externalRef
            self.updatedAt = updatedAt
            self.timezone = timezone
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

        func canMoveTo(_ next: ManualHandoffScheduleStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualHandoffScheduleStatus.inProgress || next == ManualHandoffScheduleStatus.cancelled
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
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualHandoffScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualHandoffScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual handoff schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual handoff schedule") \(code)"
        }

        func projectedLoad() -> Double {
            return ((score + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualHandoffSchedule {
            return ManualHandoffSchedule(
                code: code,
                label: label,
                bed: bed,
                ownerID: ownerID,
                score: score,
                externalRef: externalRef,
                updatedAt: updatedAt,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual handoff schedule in status planned.
    static func newManualHandoffSchedule(_ code: String, label: String) -> ManualHandoffSchedule {
        return ManualHandoffSchedule(
            code: code,
            label: label,
            bed: "",
            ownerID: "",
            score: 0.0,
            externalRef: "",
            updatedAt: 0,
            timezone: "",
            status: ManualHandoffScheduleStatus.planned
        )
    }
}
