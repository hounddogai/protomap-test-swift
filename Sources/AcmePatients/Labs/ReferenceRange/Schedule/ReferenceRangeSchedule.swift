import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range schedule is in its life cycle.
    enum ReferenceRangeScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a reference range schedule and its current status.
    final class ReferenceRangeSchedule {
        var code: String
        var name: String
        var channel: String
        var checksum: String
        var archived: Bool
        var budget: Double
        var status: ReferenceRangeScheduleStatus

        init(code: String, name: String, channel: String, checksum: String, archived: Bool, budget: Double, status: ReferenceRangeScheduleStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.checksum = checksum
            self.archived = archived
            self.budget = budget
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

        func canMoveTo(_ next: ReferenceRangeScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
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

        func moveTo(_ next: ReferenceRangeScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> ReferenceRangeSchedule {
            return ReferenceRangeSchedule(
                code: code,
                name: name,
                channel: channel,
                checksum: checksum,
                archived: archived,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a reference range schedule in status requested.
    static func newReferenceRangeSchedule(_ code: String, name: String) -> ReferenceRangeSchedule {
        return ReferenceRangeSchedule(
            code: code,
            name: name,
            channel: "",
            checksum: "",
            archived: false,
            budget: 0.0,
            status: ReferenceRangeScheduleStatus.requested
        )
    }
}
