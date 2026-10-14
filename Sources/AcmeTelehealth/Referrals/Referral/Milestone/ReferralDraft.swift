import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral draft is in its life cycle.
    enum ReferralDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A referral draft. Its code is unique within a tenant.
    final class ReferralDraft {
        var code: String
        var name: String
        var channel: String
        var attempts: Int
        var floorValue: Double
        var copay: Double
        var sequence: Int
        var status: ReferralDraftStatus

        init(code: String, name: String, channel: String, attempts: Int, floorValue: Double, copay: Double, sequence: Int, status: ReferralDraftStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.attempts = attempts
            self.floorValue = floorValue
            self.copay = copay
            self.sequence = sequence
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

        func canMoveTo(_ next: ReferralDraftStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReferralDraftStatus.rejected || next == ReferralDraftStatus.withdrawn
            case .approved:
                return next == ReferralDraftStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ReferralDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netLoad() -> Double {
            return ((Double(attempts) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralDraft {
            return ReferralDraft(
                code: code,
                name: name,
                channel: channel,
                attempts: attempts,
                floorValue: floorValue,
                copay: copay,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a referral draft in status proposed.
    static func newReferralDraft(_ code: String, name: String) -> ReferralDraft {
        return ReferralDraft(
            code: code,
            name: name,
            channel: "",
            attempts: 0,
            floorValue: 0.0,
            copay: 0.0,
            sequence: 0,
            status: ReferralDraftStatus.proposed
        )
    }
}
