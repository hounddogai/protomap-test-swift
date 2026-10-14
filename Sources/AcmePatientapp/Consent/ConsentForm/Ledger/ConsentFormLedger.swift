import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form ledger is in its life cycle.
    enum ConsentFormLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A consent form ledger. Its code is unique within a tenant.
    final class ConsentFormLedger {
        var code: String
        var title: String
        var unit: String
        var threshold: Double
        var retries: Int
        var cost: Double
        var minimum: Double
        var patientRef: String
        var notes: String
        var status: ConsentFormLedgerStatus

        init(code: String, title: String, unit: String, threshold: Double, retries: Int, cost: Double, minimum: Double, patientRef: String, notes: String, status: ConsentFormLedgerStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.threshold = threshold
            self.retries = retries
            self.cost = cost
            self.minimum = minimum
            self.patientRef = patientRef
            self.notes = notes
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

        func canMoveTo(_ next: ConsentFormLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ConsentFormLedgerStatus.approved || next == ConsentFormLedgerStatus.rejected
            case .approved:
                return next == ConsentFormLedgerStatus.rejected || next == ConsentFormLedgerStatus.withdrawn
            case .rejected:
                return next == ConsentFormLedgerStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((minimum - cost) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormLedger {
            return ConsentFormLedger(
                code: code,
                title: title,
                unit: unit,
                threshold: threshold,
                retries: retries,
                cost: cost,
                minimum: minimum,
                patientRef: patientRef,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a consent form ledger in status proposed.
    static func newConsentFormLedger(_ code: String, title: String) -> ConsentFormLedger {
        return ConsentFormLedger(
            code: code,
            title: title,
            unit: "",
            threshold: 0.0,
            retries: 0,
            cost: 0.0,
            minimum: 0.0,
            patientRef: "",
            notes: "",
            status: ConsentFormLedgerStatus.proposed
        )
    }
}
