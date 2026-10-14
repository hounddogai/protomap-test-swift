import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution ledger is in its life cycle.
    enum SubstitutionLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a substitution ledger and its current status.
    final class SubstitutionLedger {
        var code: String
        var label: String
        var retries: Int
        var refills: Int
        var category: String
        var ward: String
        var limit: Int
        var ratio: Double
        var checksum: String
        var specialty: String
        var cost: Double
        var status: SubstitutionLedgerStatus

        init(code: String, label: String, retries: Int, refills: Int, category: String, ward: String, limit: Int, ratio: Double, checksum: String, specialty: String, cost: Double, status: SubstitutionLedgerStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.refills = refills
            self.category = category
            self.ward = ward
            self.limit = limit
            self.ratio = ratio
            self.checksum = checksum
            self.specialty = specialty
            self.cost = cost
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

        func canMoveTo(_ next: SubstitutionLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SubstitutionLedgerStatus.inReview || next == SubstitutionLedgerStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SubstitutionLedgerStatus.reopened
            case .reopened:
                return next == SubstitutionLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("substitution ledger") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(refills) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionLedger {
            return SubstitutionLedger(
                code: code,
                label: label,
                retries: retries,
                refills: refills,
                category: category,
                ward: ward,
                limit: limit,
                ratio: ratio,
                checksum: checksum,
                specialty: specialty,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a substitution ledger in status open.
    static func newSubstitutionLedger(_ code: String, label: String) -> SubstitutionLedger {
        return SubstitutionLedger(
            code: code,
            label: label,
            retries: 0,
            refills: 0,
            category: "",
            ward: "",
            limit: 0,
            ratio: 0.0,
            checksum: "",
            specialty: "",
            cost: 0.0,
            status: SubstitutionLedgerStatus.`open`
        )
    }
}
