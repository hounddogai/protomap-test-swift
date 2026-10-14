import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral ledger is in its life cycle.
    enum ReferralLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A referral ledger as the referral team keeps it.
    final class ReferralLedger {
        var code: String
        var name: String
        var budget: Double
        var attempts: Int
        var specialty: String
        var acuity: Int
        var title: String
        var patientRef: String
        var checksum: String
        var version: Int
        var status: ReferralLedgerStatus

        init(code: String, name: String, budget: Double, attempts: Int, specialty: String, acuity: Int, title: String, patientRef: String, checksum: String, version: Int, status: ReferralLedgerStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.attempts = attempts
            self.specialty = specialty
            self.acuity = acuity
            self.title = title
            self.patientRef = patientRef
            self.checksum = checksum
            self.version = version
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

        func canMoveTo(_ next: ReferralLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == ReferralLedgerStatus.published
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

        func moveTo(_ next: ReferralLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netVolume() -> Double {
            return (Double(acuity) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> ReferralLedger {
            return ReferralLedger(
                code: code,
                name: name,
                budget: budget,
                attempts: attempts,
                specialty: specialty,
                acuity: acuity,
                title: title,
                patientRef: patientRef,
                checksum: checksum,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a referral ledger in status created.
    static func newReferralLedger(_ code: String, name: String) -> ReferralLedger {
        return ReferralLedger(
            code: code,
            name: name,
            budget: 0.0,
            attempts: 0,
            specialty: "",
            acuity: 0,
            title: "",
            patientRef: "",
            checksum: "",
            version: 0,
            status: ReferralLedgerStatus.created
        )
    }
}
