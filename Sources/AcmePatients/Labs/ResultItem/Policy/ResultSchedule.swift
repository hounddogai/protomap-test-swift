import AcmePlatform
import Foundation

extension Labs {
    /// Where a result schedule is in its life cycle.
    enum ResultScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result schedule as the result team keeps it.
    final class ResultSchedule {
        var code: String
        var title: String
        var payer: String
        var reviewer: String
        var ownerID: String
        var timezone: String
        var unit: String
        var approved: Bool
        var facility: String
        var revision: Int
        var status: ResultScheduleStatus

        init(code: String, title: String, payer: String, reviewer: String, ownerID: String, timezone: String, unit: String, approved: Bool, facility: String, revision: Int, status: ResultScheduleStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.timezone = timezone
            self.unit = unit
            self.approved = approved
            self.facility = facility
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ResultScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> ResultSchedule {
            return ResultSchedule(
                code: code,
                title: title,
                payer: payer,
                reviewer: reviewer,
                ownerID: ownerID,
                timezone: timezone,
                unit: unit,
                approved: approved,
                facility: facility,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a result schedule in status requested.
    static func newResultSchedule(_ code: String, title: String) -> ResultSchedule {
        return ResultSchedule(
            code: code,
            title: title,
            payer: "",
            reviewer: "",
            ownerID: "",
            timezone: "",
            unit: "",
            approved: false,
            facility: "",
            revision: 0,
            status: ResultScheduleStatus.requested
        )
    }
}
