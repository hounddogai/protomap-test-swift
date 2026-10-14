import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling task ledger is in its life cycle.
    enum RollingTaskLedgerStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling task ledger. Its code is unique within a tenant.
    final class RollingTaskLedger {
        var code: String
        var title: String
        var allergy: String
        var revision: Int
        var minimum: Double
        var copay: Double
        var currency: String
        var contactEmail: String
        var status: RollingTaskLedgerStatus

        init(code: String, title: String, allergy: String, revision: Int, minimum: Double, copay: Double, currency: String, contactEmail: String, status: RollingTaskLedgerStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.revision = revision
            self.minimum = minimum
            self.copay = copay
            self.currency = currency
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingTaskLedgerStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingTaskLedgerStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingTaskLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling task ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (minimum * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> RollingTaskLedger {
            return RollingTaskLedger(
                code: code,
                title: title,
                allergy: allergy,
                revision: revision,
                minimum: minimum,
                copay: copay,
                currency: currency,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling task ledger in status new.
    static func newRollingTaskLedger(_ code: String, title: String) -> RollingTaskLedger {
        return RollingTaskLedger(
            code: code,
            title: title,
            allergy: "",
            revision: 0,
            minimum: 0.0,
            copay: 0.0,
            currency: "",
            contactEmail: "",
            status: RollingTaskLedgerStatus.new
        )
    }
}
