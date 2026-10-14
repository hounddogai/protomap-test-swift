import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted follow up manifest is in its life cycle.
    enum WeightedFollowUpManifestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted follow up manifest. Its code is unique within a tenant.
    final class WeightedFollowUpManifest {
        var code: String
        var title: String
        var archived: Bool
        var category: String
        var limit: Int
        var summary: String
        var timezone: String
        var clinicianID: String
        var status: WeightedFollowUpManifestStatus

        init(code: String, title: String, archived: Bool, category: String, limit: Int, summary: String, timezone: String, clinicianID: String, status: WeightedFollowUpManifestStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.category = category
            self.limit = limit
            self.summary = summary
            self.timezone = timezone
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: WeightedFollowUpManifestStatus) -> Bool {
            switch status {
            case .planned:
                return next == WeightedFollowUpManifestStatus.completed
            case .scheduled:
                return next == WeightedFollowUpManifestStatus.completed
            case .inProgress:
                return next == WeightedFollowUpManifestStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: WeightedFollowUpManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted follow up manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> WeightedFollowUpManifest {
            return WeightedFollowUpManifest(
                code: code,
                title: title,
                archived: archived,
                category: category,
                limit: limit,
                summary: summary,
                timezone: timezone,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted follow up manifest in status planned.
    static func newWeightedFollowUpManifest(_ code: String, title: String) -> WeightedFollowUpManifest {
        return WeightedFollowUpManifest(
            code: code,
            title: title,
            archived: false,
            category: "",
            limit: 0,
            summary: "",
            timezone: "",
            clinicianID: "",
            status: WeightedFollowUpManifestStatus.planned
        )
    }
}
