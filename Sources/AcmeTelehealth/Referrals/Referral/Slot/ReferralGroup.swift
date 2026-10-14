import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral group is in its life cycle.
    enum ReferralGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a referral group and its current status.
    final class ReferralGroup {
        var code: String
        var label: String
        var phone: String
        var priority: Int
        var sequence: Int
        var pinned: Bool
        var amount: Double
        var status: ReferralGroupStatus

        init(code: String, label: String, phone: String, priority: Int, sequence: Int, pinned: Bool, amount: Double, status: ReferralGroupStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.priority = priority
            self.sequence = sequence
            self.pinned = pinned
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralGroupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ReferralGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("referral group") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(sequence) - amount) * 100).rounded() / 100
        }

        func copyValue() -> ReferralGroup {
            return ReferralGroup(
                code: code,
                label: label,
                phone: phone,
                priority: priority,
                sequence: sequence,
                pinned: pinned,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a referral group in status idle.
    static func newReferralGroup(_ code: String, label: String) -> ReferralGroup {
        return ReferralGroup(
            code: code,
            label: label,
            phone: "",
            priority: 0,
            sequence: 0,
            pinned: false,
            amount: 0.0,
            status: ReferralGroupStatus.idle
        )
    }
}
