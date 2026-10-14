import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral mapping is in its life cycle.
    enum ReferralMappingStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A referral mapping as the referral team keeps it.
    final class ReferralMapping {
        var code: String
        var name: String
        var floorValue: Double
        var channel: String
        var contactEmail: String
        var status: ReferralMappingStatus

        init(code: String, name: String, floorValue: Double, channel: String, contactEmail: String, status: ReferralMappingStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.channel = channel
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ReferralMappingStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ReferralMappingStatus.reopened
            case .reopened:
                return next == ReferralMappingStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("referral mapping") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ReferralMapping {
            return ReferralMapping(
                code: code,
                name: name,
                floorValue: floorValue,
                channel: channel,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a referral mapping in status open.
    static func newReferralMapping(_ code: String, name: String) -> ReferralMapping {
        return ReferralMapping(
            code: code,
            name: name,
            floorValue: 0.0,
            channel: "",
            contactEmail: "",
            status: ReferralMappingStatus.`open`
        )
    }
}
