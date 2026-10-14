import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending referral milestone is in its life cycle.
    enum PendingReferralMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A pending referral milestone. Its code is unique within a tenant.
    final class PendingReferralMilestone {
        var code: String
        var name: String
        var unit: String
        var expiresAt: Int
        var payer: String
        var minimum: Double
        var createdAt: Int
        var contactEmail: String
        var allergy: String
        var status: PendingReferralMilestoneStatus

        init(code: String, name: String, unit: String, expiresAt: Int, payer: String, minimum: Double, createdAt: Int, contactEmail: String, allergy: String, status: PendingReferralMilestoneStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.expiresAt = expiresAt
            self.payer = payer
            self.minimum = minimum
            self.createdAt = createdAt
            self.contactEmail = contactEmail
            self.allergy = allergy
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

        func canMoveTo(_ next: PendingReferralMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingReferralMilestoneStatus.suspended || next == PendingReferralMilestoneStatus.closed
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingReferralMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending referral milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(createdAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> PendingReferralMilestone {
            return PendingReferralMilestone(
                code: code,
                name: name,
                unit: unit,
                expiresAt: expiresAt,
                payer: payer,
                minimum: minimum,
                createdAt: createdAt,
                contactEmail: contactEmail,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending referral milestone in status draft.
    static func newPendingReferralMilestone(_ code: String, name: String) -> PendingReferralMilestone {
        return PendingReferralMilestone(
            code: code,
            name: name,
            unit: "",
            expiresAt: 0,
            payer: "",
            minimum: 0.0,
            createdAt: 0,
            contactEmail: "",
            allergy: "",
            status: PendingReferralMilestoneStatus.draft
        )
    }
}
