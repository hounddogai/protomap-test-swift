import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral claim is in its life cycle.
    enum ReferralClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A referral claim. Its code is unique within a tenant.
    final class ReferralClaim {
        var code: String
        var name: String
        var allergy: String
        var archived: Bool
        var channel: String
        var createdAt: Int
        var discount: Double
        var capacity: Int
        var sequence: Int
        var notes: String
        var status: ReferralClaimStatus

        init(code: String, name: String, allergy: String, archived: Bool, channel: String, createdAt: Int, discount: Double, capacity: Int, sequence: Int, notes: String, status: ReferralClaimStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.archived = archived
            self.channel = channel
            self.createdAt = createdAt
            self.discount = discount
            self.capacity = capacity
            self.sequence = sequence
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ReferralClaimStatus.rejected
            case .rejected:
                return next == ReferralClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netExposure() -> Double {
            return ((Double(sequence) + discount) * 100).rounded() / 100
        }

        func copyValue() -> ReferralClaim {
            return ReferralClaim(
                code: code,
                name: name,
                allergy: allergy,
                archived: archived,
                channel: channel,
                createdAt: createdAt,
                discount: discount,
                capacity: capacity,
                sequence: sequence,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a referral claim in status proposed.
    static func newReferralClaim(_ code: String, name: String) -> ReferralClaim {
        return ReferralClaim(
            code: code,
            name: name,
            allergy: "",
            archived: false,
            channel: "",
            createdAt: 0,
            discount: 0.0,
            capacity: 0,
            sequence: 0,
            notes: "",
            status: ReferralClaimStatus.proposed
        )
    }
}
