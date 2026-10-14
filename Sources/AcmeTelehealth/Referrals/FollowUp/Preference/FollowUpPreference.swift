import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up preference is in its life cycle.
    enum FollowUpPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A follow up preference. Its code is unique within a tenant.
    final class FollowUpPreference {
        var code: String
        var name: String
        var procedureCode: String
        var allergy: String
        var category: String
        var revision: Int
        var facility: String
        var visible: Bool
        var attempts: Int
        var timezone: String
        var status: FollowUpPreferenceStatus

        init(code: String, name: String, procedureCode: String, allergy: String, category: String, revision: Int, facility: String, visible: Bool, attempts: Int, timezone: String, status: FollowUpPreferenceStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.allergy = allergy
            self.category = category
            self.revision = revision
            self.facility = facility
            self.visible = visible
            self.attempts = attempts
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

        func canMoveTo(_ next: FollowUpPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == FollowUpPreferenceStatus.cancelled
            case .scheduled:
                return next == FollowUpPreferenceStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FollowUpPreferenceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return ((Double(revision) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpPreference {
            return FollowUpPreference(
                code: code,
                name: name,
                procedureCode: procedureCode,
                allergy: allergy,
                category: category,
                revision: revision,
                facility: facility,
                visible: visible,
                attempts: attempts,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a follow up preference in status planned.
    static func newFollowUpPreference(_ code: String, name: String) -> FollowUpPreference {
        return FollowUpPreference(
            code: code,
            name: name,
            procedureCode: "",
            allergy: "",
            category: "",
            revision: 0,
            facility: "",
            visible: false,
            attempts: 0,
            timezone: "",
            status: FollowUpPreferenceStatus.planned
        )
    }
}
