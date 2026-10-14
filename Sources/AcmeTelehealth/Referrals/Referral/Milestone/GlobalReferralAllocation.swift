import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global referral allocation is in its life cycle.
    enum GlobalReferralAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global referral allocation as the referral team keeps it.
    final class GlobalReferralAllocation {
        var code: String
        var label: String
        var segment: String
        var expiresAt: Int
        var revision: Int
        var active: Bool
        var name: String
        var startsAt: Int
        var status: GlobalReferralAllocationStatus

        init(code: String, label: String, segment: String, expiresAt: Int, revision: Int, active: Bool, name: String, startsAt: Int, status: GlobalReferralAllocationStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.expiresAt = expiresAt
            self.revision = revision
            self.active = active
            self.name = name
            self.startsAt = startsAt
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

        func canMoveTo(_ next: GlobalReferralAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalReferralAllocationStatus.inReview || next == GlobalReferralAllocationStatus.resolved
            case .inReview:
                return next == GlobalReferralAllocationStatus.reopened || next == GlobalReferralAllocationStatus.archived
            case .resolved:
                return next == GlobalReferralAllocationStatus.reopened || next == GlobalReferralAllocationStatus.archived
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

        func moveTo(_ next: GlobalReferralAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global referral allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("global referral allocation") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(expiresAt) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReferralAllocation {
            return GlobalReferralAllocation(
                code: code,
                label: label,
                segment: segment,
                expiresAt: expiresAt,
                revision: revision,
                active: active,
                name: name,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global referral allocation in status open.
    static func newGlobalReferralAllocation(_ code: String, label: String) -> GlobalReferralAllocation {
        return GlobalReferralAllocation(
            code: code,
            label: label,
            segment: "",
            expiresAt: 0,
            revision: 0,
            active: false,
            name: "",
            startsAt: 0,
            status: GlobalReferralAllocationStatus.`open`
        )
    }
}
