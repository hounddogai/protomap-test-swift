import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary study schedule is in its life cycle.
    enum PrimaryStudyScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary study schedule and its current status.
    final class PrimaryStudySchedule {
        var code: String
        var label: String
        var limit: Int
        var visitMinutes: Int
        var name: String
        var encounterID: String
        var ceiling: Double
        var status: PrimaryStudyScheduleStatus

        init(code: String, label: String, limit: Int, visitMinutes: Int, name: String, encounterID: String, ceiling: Double, status: PrimaryStudyScheduleStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.name = name
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryStudyScheduleStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryStudyScheduleStatus.validated
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PrimaryStudyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary study schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary study schedule") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(visitMinutes) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStudySchedule {
            return PrimaryStudySchedule(
                code: code,
                label: label,
                limit: limit,
                visitMinutes: visitMinutes,
                name: name,
                encounterID: encounterID,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary study schedule in status created.
    static func newPrimaryStudySchedule(_ code: String, label: String) -> PrimaryStudySchedule {
        return PrimaryStudySchedule(
            code: code,
            label: label,
            limit: 0,
            visitMinutes: 0,
            name: "",
            encounterID: "",
            ceiling: 0.0,
            status: PrimaryStudyScheduleStatus.created
        )
    }
}
