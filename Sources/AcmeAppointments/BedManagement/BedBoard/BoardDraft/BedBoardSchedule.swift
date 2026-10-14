import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board schedule is in its life cycle.
    enum BedBoardScheduleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One bed board schedule, with what the planners need to act on it.
    final class BedBoardSchedule {
        var code: String
        var name: String
        var retries: Int
        var reviewer: String
        var checksum: String
        var status: BedBoardScheduleStatus

        init(code: String, name: String, retries: Int, reviewer: String, checksum: String, status: BedBoardScheduleStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.reviewer = reviewer
            self.checksum = checksum
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

        func canMoveTo(_ next: BedBoardScheduleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BedBoardScheduleStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BedBoardScheduleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> BedBoardSchedule {
            return BedBoardSchedule(
                code: code,
                name: name,
                retries: retries,
                reviewer: reviewer,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board schedule in status open.
    static func newBedBoardSchedule(_ code: String, name: String) -> BedBoardSchedule {
        return BedBoardSchedule(
            code: code,
            name: name,
            retries: 0,
            reviewer: "",
            checksum: "",
            status: BedBoardScheduleStatus.`open`
        )
    }
}
