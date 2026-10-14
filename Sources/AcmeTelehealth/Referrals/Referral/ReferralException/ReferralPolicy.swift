import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral policy is in its life cycle.
    enum ReferralPolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a referral policy and its current status.
    final class ReferralPolicy {
        var code: String
        var title: String
        var payer: String
        var pinned: Bool
        var contactEmail: String
        var weight: Double
        var batchSize: Int
        var currency: String
        var cost: Double
        var visible: Bool
        var notes: String
        var status: ReferralPolicyStatus

        init(code: String, title: String, payer: String, pinned: Bool, contactEmail: String, weight: Double, batchSize: Int, currency: String, cost: Double, visible: Bool, notes: String, status: ReferralPolicyStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.weight = weight
            self.batchSize = batchSize
            self.currency = currency
            self.cost = cost
            self.visible = visible
            self.notes = notes
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

        func canMoveTo(_ next: ReferralPolicyStatus) -> Bool {
            switch status {
            case .planned:
                return next == ReferralPolicyStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ReferralPolicyStatus.completed || next == ReferralPolicyStatus.cancelled
            case .completed:
                return next == ReferralPolicyStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral policy") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) + weight) * 100).rounded() / 100
        }

        func copyValue() -> ReferralPolicy {
            return ReferralPolicy(
                code: code,
                title: title,
                payer: payer,
                pinned: pinned,
                contactEmail: contactEmail,
                weight: weight,
                batchSize: batchSize,
                currency: currency,
                cost: cost,
                visible: visible,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a referral policy in status planned.
    static func newReferralPolicy(_ code: String, title: String) -> ReferralPolicy {
        return ReferralPolicy(
            code: code,
            title: title,
            payer: "",
            pinned: false,
            contactEmail: "",
            weight: 0.0,
            batchSize: 0,
            currency: "",
            cost: 0.0,
            visible: false,
            notes: "",
            status: ReferralPolicyStatus.planned
        )
    }
}
