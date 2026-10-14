import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral proposal is in its life cycle.
    enum ReferralProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A referral proposal as the referral team keeps it.
    final class ReferralProposal {
        var code: String
        var title: String
        var approved: Bool
        var visitMinutes: Int
        var quantity: Int
        var encounterID: String
        var active: Bool
        var currency: String
        var payer: String
        var ratio: Double
        var phone: String
        var status: ReferralProposalStatus

        init(code: String, title: String, approved: Bool, visitMinutes: Int, quantity: Int, encounterID: String, active: Bool, currency: String, payer: String, ratio: Double, phone: String, status: ReferralProposalStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.encounterID = encounterID
            self.active = active
            self.currency = currency
            self.payer = payer
            self.ratio = ratio
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ReferralProposalStatus.closed
            case .active:
                return next == ReferralProposalStatus.suspended || next == ReferralProposalStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ReferralProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral proposal") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(quantity) * ratio * 100).rounded() / 100
        }

        func copyValue() -> ReferralProposal {
            return ReferralProposal(
                code: code,
                title: title,
                approved: approved,
                visitMinutes: visitMinutes,
                quantity: quantity,
                encounterID: encounterID,
                active: active,
                currency: currency,
                payer: payer,
                ratio: ratio,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a referral proposal in status draft.
    static func newReferralProposal(_ code: String, title: String) -> ReferralProposal {
        return ReferralProposal(
            code: code,
            title: title,
            approved: false,
            visitMinutes: 0,
            quantity: 0,
            encounterID: "",
            active: false,
            currency: "",
            payer: "",
            ratio: 0.0,
            phone: "",
            status: ReferralProposalStatus.draft
        )
    }
}
