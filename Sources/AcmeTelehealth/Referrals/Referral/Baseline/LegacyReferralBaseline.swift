import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy referral baseline is in its life cycle.
    enum LegacyReferralBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One legacy referral baseline, with what the planners need to act on it.
    final class LegacyReferralBaseline {
        var code: String
        var label: String
        var ceiling: Double
        var amount: Double
        var summary: String
        var endsAt: Int
        var sequence: Int
        var minimum: Double
        var revision: Int
        var status: LegacyReferralBaselineStatus

        init(code: String, label: String, ceiling: Double, amount: Double, summary: String, endsAt: Int, sequence: Int, minimum: Double, revision: Int, status: LegacyReferralBaselineStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.amount = amount
            self.summary = summary
            self.endsAt = endsAt
            self.sequence = sequence
            self.minimum = minimum
            self.revision = revision
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

        func canMoveTo(_ next: LegacyReferralBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyReferralBaselineStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyReferralBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy referral baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedLoad() -> Double {
            return ((Double(revision) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferralBaseline {
            return LegacyReferralBaseline(
                code: code,
                label: label,
                ceiling: ceiling,
                amount: amount,
                summary: summary,
                endsAt: endsAt,
                sequence: sequence,
                minimum: minimum,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy referral baseline in status proposed.
    static func newLegacyReferralBaseline(_ code: String, label: String) -> LegacyReferralBaseline {
        return LegacyReferralBaseline(
            code: code,
            label: label,
            ceiling: 0.0,
            amount: 0.0,
            summary: "",
            endsAt: 0,
            sequence: 0,
            minimum: 0.0,
            revision: 0,
            status: LegacyReferralBaselineStatus.proposed
        )
    }
}
