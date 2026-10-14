import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession ledger is in its life cycle.
    enum AccessionLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A accession ledger as the accession team keeps it.
    final class AccessionLedger {
        var code: String
        var name: String
        var procedureCode: String
        var active: Bool
        var discount: Double
        var patientRef: String
        var budget: Double
        var weight: Double
        var revision: Int
        var refills: Int
        var rate: Double
        var status: AccessionLedgerStatus

        init(code: String, name: String, procedureCode: String, active: Bool, discount: Double, patientRef: String, budget: Double, weight: Double, revision: Int, refills: Int, rate: Double, status: AccessionLedgerStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.active = active
            self.discount = discount
            self.patientRef = patientRef
            self.budget = budget
            self.weight = weight
            self.revision = revision
            self.refills = refills
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == AccessionLedgerStatus.inProgress
            case .scheduled:
                return next == AccessionLedgerStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == AccessionLedgerStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((discount - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionLedger {
            return AccessionLedger(
                code: code,
                name: name,
                procedureCode: procedureCode,
                active: active,
                discount: discount,
                patientRef: patientRef,
                budget: budget,
                weight: weight,
                revision: revision,
                refills: refills,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession ledger in status planned.
    static func newAccessionLedger(_ code: String, name: String) -> AccessionLedger {
        return AccessionLedger(
            code: code,
            name: name,
            procedureCode: "",
            active: false,
            discount: 0.0,
            patientRef: "",
            budget: 0.0,
            weight: 0.0,
            revision: 0,
            refills: 0,
            rate: 0.0,
            status: AccessionLedgerStatus.planned
        )
    }
}
