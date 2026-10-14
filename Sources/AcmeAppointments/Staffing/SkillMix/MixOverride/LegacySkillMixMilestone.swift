import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy skill mix milestone is in its life cycle.
    enum LegacySkillMixMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy skill mix milestone. Its code is unique within a tenant.
    final class LegacySkillMixMilestone {
        var code: String
        var title: String
        var weight: Double
        var locale: String
        var encounterID: String
        var specialty: String
        var revision: Int
        var archived: Bool
        var checksum: String
        var windowDays: Int
        var approved: Bool
        var status: LegacySkillMixMilestoneStatus

        init(code: String, title: String, weight: Double, locale: String, encounterID: String, specialty: String, revision: Int, archived: Bool, checksum: String, windowDays: Int, approved: Bool, status: LegacySkillMixMilestoneStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.locale = locale
            self.encounterID = encounterID
            self.specialty = specialty
            self.revision = revision
            self.archived = archived
            self.checksum = checksum
            self.windowDays = windowDays
            self.approved = approved
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

        func canMoveTo(_ next: LegacySkillMixMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacySkillMixMilestoneStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacySkillMixMilestoneStatus.reopened || next == LegacySkillMixMilestoneStatus.archived
            case .reopened:
                return next == LegacySkillMixMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacySkillMixMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy skill mix milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return (weight * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> LegacySkillMixMilestone {
            return LegacySkillMixMilestone(
                code: code,
                title: title,
                weight: weight,
                locale: locale,
                encounterID: encounterID,
                specialty: specialty,
                revision: revision,
                archived: archived,
                checksum: checksum,
                windowDays: windowDays,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy skill mix milestone in status open.
    static func newLegacySkillMixMilestone(_ code: String, title: String) -> LegacySkillMixMilestone {
        return LegacySkillMixMilestone(
            code: code,
            title: title,
            weight: 0.0,
            locale: "",
            encounterID: "",
            specialty: "",
            revision: 0,
            archived: false,
            checksum: "",
            windowDays: 0,
            approved: false,
            status: LegacySkillMixMilestoneStatus.`open`
        )
    }
}
