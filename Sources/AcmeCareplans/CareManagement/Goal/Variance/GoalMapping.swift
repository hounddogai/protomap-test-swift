import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal mapping is in its life cycle.
    enum GoalMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A goal mapping. Its code is unique within a tenant.
    final class GoalMapping {
        var code: String
        var label: String
        var specialty: String
        var approved: Bool
        var bed: String
        var revision: Int
        var payer: String
        var allergy: String
        var durationMinutes: Int
        var title: String
        var region: String
        var status: GoalMappingStatus

        init(code: String, label: String, specialty: String, approved: Bool, bed: String, revision: Int, payer: String, allergy: String, durationMinutes: Int, title: String, region: String, status: GoalMappingStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.approved = approved
            self.bed = bed
            self.revision = revision
            self.payer = payer
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.title = title
            self.region = region
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

        func canMoveTo(_ next: GoalMappingStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GoalMappingStatus.resolved || next == GoalMappingStatus.archived
            case .resolved:
                return next == GoalMappingStatus.reopened || next == GoalMappingStatus.archived
            case .reopened:
                return next == GoalMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> GoalMapping {
            return GoalMapping(
                code: code,
                label: label,
                specialty: specialty,
                approved: approved,
                bed: bed,
                revision: revision,
                payer: payer,
                allergy: allergy,
                durationMinutes: durationMinutes,
                title: title,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a goal mapping in status open.
    static func newGoalMapping(_ code: String, label: String) -> GoalMapping {
        return GoalMapping(
            code: code,
            label: label,
            specialty: "",
            approved: false,
            bed: "",
            revision: 0,
            payer: "",
            allergy: "",
            durationMinutes: 0,
            title: "",
            region: "",
            status: GoalMappingStatus.`open`
        )
    }
}
