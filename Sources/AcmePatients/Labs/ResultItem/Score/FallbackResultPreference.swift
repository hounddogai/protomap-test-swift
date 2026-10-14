import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback result preference is in its life cycle.
    enum FallbackResultPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback result preference, with what the planners need to act on it.
    final class FallbackResultPreference {
        var code: String
        var title: String
        var facility: String
        var encounterID: String
        var approved: Bool
        var phone: String
        var procedureCode: String
        var priority: Int
        var country: String
        var graceDays: Int
        var status: FallbackResultPreferenceStatus

        init(code: String, title: String, facility: String, encounterID: String, approved: Bool, phone: String, procedureCode: String, priority: Int, country: String, graceDays: Int, status: FallbackResultPreferenceStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.encounterID = encounterID
            self.approved = approved
            self.phone = phone
            self.procedureCode = procedureCode
            self.priority = priority
            self.country = country
            self.graceDays = graceDays
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

        func canMoveTo(_ next: FallbackResultPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackResultPreferenceStatus.inProgress || next == FallbackResultPreferenceStatus.completed
            case .inProgress:
                return next == FallbackResultPreferenceStatus.cancelled
            case .completed:
                return next == FallbackResultPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackResultPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback result preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return ((Double(graceDays) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackResultPreference {
            return FallbackResultPreference(
                code: code,
                title: title,
                facility: facility,
                encounterID: encounterID,
                approved: approved,
                phone: phone,
                procedureCode: procedureCode,
                priority: priority,
                country: country,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a fallback result preference in status planned.
    static func newFallbackResultPreference(_ code: String, title: String) -> FallbackResultPreference {
        return FallbackResultPreference(
            code: code,
            title: title,
            facility: "",
            encounterID: "",
            approved: false,
            phone: "",
            procedureCode: "",
            priority: 0,
            country: "",
            graceDays: 0,
            status: FallbackResultPreferenceStatus.planned
        )
    }
}
