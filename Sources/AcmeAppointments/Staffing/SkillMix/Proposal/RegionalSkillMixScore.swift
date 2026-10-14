import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional skill mix score is in its life cycle.
    enum RegionalSkillMixScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A regional skill mix score. Its code is unique within a tenant.
    final class RegionalSkillMixScore {
        var code: String
        var label: String
        var region: String
        var discount: Double
        var specialty: String
        var revision: Int
        var contactEmail: String
        var country: String
        var archived: Bool
        var weight: Double
        var status: RegionalSkillMixScoreStatus

        init(code: String, label: String, region: String, discount: Double, specialty: String, revision: Int, contactEmail: String, country: String, archived: Bool, weight: Double, status: RegionalSkillMixScoreStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.discount = discount
            self.specialty = specialty
            self.revision = revision
            self.contactEmail = contactEmail
            self.country = country
            self.archived = archived
            self.weight = weight
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

        func canMoveTo(_ next: RegionalSkillMixScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == RegionalSkillMixScoreStatus.scheduled
            case .scheduled:
                return next == RegionalSkillMixScoreStatus.inProgress || next == RegionalSkillMixScoreStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RegionalSkillMixScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSkillMixScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional skill mix score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((Double(revision) - weight) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSkillMixScore {
            return RegionalSkillMixScore(
                code: code,
                label: label,
                region: region,
                discount: discount,
                specialty: specialty,
                revision: revision,
                contactEmail: contactEmail,
                country: country,
                archived: archived,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional skill mix score in status planned.
    static func newRegionalSkillMixScore(_ code: String, label: String) -> RegionalSkillMixScore {
        return RegionalSkillMixScore(
            code: code,
            label: label,
            region: "",
            discount: 0.0,
            specialty: "",
            revision: 0,
            contactEmail: "",
            country: "",
            archived: false,
            weight: 0.0,
            status: RegionalSkillMixScoreStatus.planned
        )
    }
}
