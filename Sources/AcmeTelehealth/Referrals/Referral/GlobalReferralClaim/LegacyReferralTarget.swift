import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy referral target is in its life cycle.
    enum LegacyReferralTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One legacy referral target, with what the planners need to act on it.
    final class LegacyReferralTarget {
        var code: String
        var title: String
        var updatedAt: Int
        var ceiling: Double
        var name: String
        var endsAt: Int
        var encounterID: String
        var description: String
        var status: LegacyReferralTargetStatus

        init(code: String, title: String, updatedAt: Int, ceiling: Double, name: String, endsAt: Int, encounterID: String, description: String, status: LegacyReferralTargetStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.name = name
            self.endsAt = endsAt
            self.encounterID = encounterID
            self.description = description
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

        func canMoveTo(_ next: LegacyReferralTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyReferralTargetStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyReferralTargetStatus.reopened || next == LegacyReferralTargetStatus.archived
            case .reopened:
                return next == LegacyReferralTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyReferralTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy referral target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy referral target") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(endsAt) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferralTarget {
            return LegacyReferralTarget(
                code: code,
                title: title,
                updatedAt: updatedAt,
                ceiling: ceiling,
                name: name,
                endsAt: endsAt,
                encounterID: encounterID,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy referral target in status open.
    static func newLegacyReferralTarget(_ code: String, title: String) -> LegacyReferralTarget {
        return LegacyReferralTarget(
            code: code,
            title: title,
            updatedAt: 0,
            ceiling: 0.0,
            name: "",
            endsAt: 0,
            encounterID: "",
            description: "",
            status: LegacyReferralTargetStatus.`open`
        )
    }
}
