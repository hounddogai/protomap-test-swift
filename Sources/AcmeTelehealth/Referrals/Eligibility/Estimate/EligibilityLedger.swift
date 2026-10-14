import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility ledger is in its life cycle.
    enum EligibilityLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A eligibility ledger. Its code is unique within a tenant.
    final class EligibilityLedger {
        var code: String
        var label: String
        var active: Bool
        var bed: String
        var score: Double
        var checksum: String
        var pinned: Bool
        var contactEmail: String
        var endsAt: Int
        var updatedAt: Int
        var sequence: Int
        var status: EligibilityLedgerStatus

        init(code: String, label: String, active: Bool, bed: String, score: Double, checksum: String, pinned: Bool, contactEmail: String, endsAt: Int, updatedAt: Int, sequence: Int, status: EligibilityLedgerStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.bed = bed
            self.score = score
            self.checksum = checksum
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.sequence = sequence
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

        func canMoveTo(_ next: EligibilityLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == EligibilityLedgerStatus.retired
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

        func moveTo(_ next: EligibilityLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("eligibility ledger") \(code)"
        }

        func netValue() -> Double {
            return ((score - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityLedger {
            return EligibilityLedger(
                code: code,
                label: label,
                active: active,
                bed: bed,
                score: score,
                checksum: checksum,
                pinned: pinned,
                contactEmail: contactEmail,
                endsAt: endsAt,
                updatedAt: updatedAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a eligibility ledger in status created.
    static func newEligibilityLedger(_ code: String, label: String) -> EligibilityLedger {
        return EligibilityLedger(
            code: code,
            label: label,
            active: false,
            bed: "",
            score: 0.0,
            checksum: "",
            pinned: false,
            contactEmail: "",
            endsAt: 0,
            updatedAt: 0,
            sequence: 0,
            status: EligibilityLedgerStatus.created
        )
    }
}
