import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional result schedule is in its life cycle.
    enum RegionalResultScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional result schedule, with what the planners need to act on it.
    final class RegionalResultSchedule {
        var code: String
        var name: String
        var tags: [String]
        var pinned: Bool
        var contactEmail: String
        var limit: Int
        var clinicianID: String
        var status: RegionalResultScheduleStatus

        init(code: String, name: String, tags: [String], pinned: Bool, contactEmail: String, limit: Int, clinicianID: String, status: RegionalResultScheduleStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.limit = limit
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: RegionalResultScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
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
                return next == RegionalResultScheduleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalResultScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional result schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional result schedule") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> RegionalResultSchedule {
            return RegionalResultSchedule(
                code: code,
                name: name,
                tags: tags,
                pinned: pinned,
                contactEmail: contactEmail,
                limit: limit,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional result schedule in status requested.
    static func newRegionalResultSchedule(_ code: String, name: String) -> RegionalResultSchedule {
        return RegionalResultSchedule(
            code: code,
            name: name,
            tags: [],
            pinned: false,
            contactEmail: "",
            limit: 0,
            clinicianID: "",
            status: RegionalResultScheduleStatus.requested
        )
    }
}
