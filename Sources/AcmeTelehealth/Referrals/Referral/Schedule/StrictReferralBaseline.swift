import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict referral baseline is in its life cycle.
    enum StrictReferralBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict referral baseline as the referral team keeps it.
    final class StrictReferralBaseline {
        var code: String
        var name: String
        var attempts: Int
        var externalRef: String
        var currency: String
        var capacity: Int
        var refills: Int
        var source: String
        var timezone: String
        var status: StrictReferralBaselineStatus

        init(code: String, name: String, attempts: Int, externalRef: String, currency: String, capacity: Int, refills: Int, source: String, timezone: String, status: StrictReferralBaselineStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.externalRef = externalRef
            self.currency = currency
            self.capacity = capacity
            self.refills = refills
            self.source = source
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictReferralBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictReferralBaselineStatus.validated || next == StrictReferralBaselineStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StrictReferralBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict referral baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return ((Double(capacity) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> StrictReferralBaseline {
            return StrictReferralBaseline(
                code: code,
                name: name,
                attempts: attempts,
                externalRef: externalRef,
                currency: currency,
                capacity: capacity,
                refills: refills,
                source: source,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a strict referral baseline in status created.
    static func newStrictReferralBaseline(_ code: String, name: String) -> StrictReferralBaseline {
        return StrictReferralBaseline(
            code: code,
            name: name,
            attempts: 0,
            externalRef: "",
            currency: "",
            capacity: 0,
            refills: 0,
            source: "",
            timezone: "",
            status: StrictReferralBaselineStatus.created
        )
    }
}
