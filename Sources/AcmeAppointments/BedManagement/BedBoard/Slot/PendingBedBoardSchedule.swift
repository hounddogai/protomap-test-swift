import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending bed board schedule is in its life cycle.
    enum PendingBedBoardScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending bed board schedule. Its code is unique within a tenant.
    final class PendingBedBoardSchedule {
        var code: String
        var title: String
        var approved: Bool
        var notes: String
        var country: String
        var durationMinutes: Int
        var threshold: Double
        var status: PendingBedBoardScheduleStatus

        init(code: String, title: String, approved: Bool, notes: String, country: String, durationMinutes: Int, threshold: Double, status: PendingBedBoardScheduleStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.notes = notes
            self.country = country
            self.durationMinutes = durationMinutes
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingBedBoardScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingBedBoardScheduleStatus.inReview || next == PendingBedBoardScheduleStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PendingBedBoardScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending bed board schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending bed board schedule") \(code)"
        }

        func projectedValue() -> Double {
            return ((threshold + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingBedBoardSchedule {
            return PendingBedBoardSchedule(
                code: code,
                title: title,
                approved: approved,
                notes: notes,
                country: country,
                durationMinutes: durationMinutes,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending bed board schedule in status open.
    static func newPendingBedBoardSchedule(_ code: String, title: String) -> PendingBedBoardSchedule {
        return PendingBedBoardSchedule(
            code: code,
            title: title,
            approved: false,
            notes: "",
            country: "",
            durationMinutes: 0,
            threshold: 0.0,
            status: PendingBedBoardScheduleStatus.`open`
        )
    }
}
