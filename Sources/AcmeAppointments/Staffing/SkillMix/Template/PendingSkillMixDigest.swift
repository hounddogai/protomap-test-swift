import AcmePlatform
import Foundation

extension Staffing {
    /// Where a pending skill mix digest is in its life cycle.
    enum PendingSkillMixDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a pending skill mix digest and its current status.
    final class PendingSkillMixDigest {
        var code: String
        var title: String
        var discount: Double
        var encounterID: String
        var notes: String
        var ceiling: Double
        var revision: Int
        var threshold: Double
        var status: PendingSkillMixDigestStatus

        init(code: String, title: String, discount: Double, encounterID: String, notes: String, ceiling: Double, revision: Int, threshold: Double, status: PendingSkillMixDigestStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.encounterID = encounterID
            self.notes = notes
            self.ceiling = ceiling
            self.revision = revision
            self.threshold = threshold
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

        func canMoveTo(_ next: PendingSkillMixDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingSkillMixDigestStatus.reopened || next == PendingSkillMixDigestStatus.archived
            case .inReview:
                return next == PendingSkillMixDigestStatus.reopened || next == PendingSkillMixDigestStatus.archived
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == PendingSkillMixDigestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSkillMixDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending skill mix digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((discount + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PendingSkillMixDigest {
            return PendingSkillMixDigest(
                code: code,
                title: title,
                discount: discount,
                encounterID: encounterID,
                notes: notes,
                ceiling: ceiling,
                revision: revision,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending skill mix digest in status open.
    static func newPendingSkillMixDigest(_ code: String, title: String) -> PendingSkillMixDigest {
        return PendingSkillMixDigest(
            code: code,
            title: title,
            discount: 0.0,
            encounterID: "",
            notes: "",
            ceiling: 0.0,
            revision: 0,
            threshold: 0.0,
            status: PendingSkillMixDigestStatus.`open`
        )
    }
}
