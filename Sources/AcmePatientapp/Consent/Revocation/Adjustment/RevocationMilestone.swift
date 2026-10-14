import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation milestone is in its life cycle.
    enum RevocationMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One revocation milestone, with what the planners need to act on it.
    final class RevocationMilestone {
        var code: String
        var title: String
        var margin: Double
        var revision: Int
        var reviewer: String
        var tags: [String]
        var payer: String
        var procedureCode: String
        var durationMinutes: Int
        var active: Bool
        var phone: String
        var status: RevocationMilestoneStatus

        init(code: String, title: String, margin: Double, revision: Int, reviewer: String, tags: [String], payer: String, procedureCode: String, durationMinutes: Int, active: Bool, phone: String, status: RevocationMilestoneStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.revision = revision
            self.reviewer = reviewer
            self.tags = tags
            self.payer = payer
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.active = active
            self.phone = phone
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

        func canMoveTo(_ next: RevocationMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RevocationMilestoneStatus.reopened
            case .inReview:
                return next == RevocationMilestoneStatus.resolved
            case .resolved:
                return next == RevocationMilestoneStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RevocationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return (Double(revision) * margin * 100).rounded() / 100
        }

        func copyValue() -> RevocationMilestone {
            return RevocationMilestone(
                code: code,
                title: title,
                margin: margin,
                revision: revision,
                reviewer: reviewer,
                tags: tags,
                payer: payer,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                active: active,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation milestone in status open.
    static func newRevocationMilestone(_ code: String, title: String) -> RevocationMilestone {
        return RevocationMilestone(
            code: code,
            title: title,
            margin: 0.0,
            revision: 0,
            reviewer: "",
            tags: [],
            payer: "",
            procedureCode: "",
            durationMinutes: 0,
            active: false,
            phone: "",
            status: RevocationMilestoneStatus.`open`
        )
    }
}
