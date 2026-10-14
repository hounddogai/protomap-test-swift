import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict disclosure ledger is in its life cycle.
    enum StrictDisclosureLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict disclosure ledger as the disclosure team keeps it.
    final class StrictDisclosureLedger {
        var code: String
        var name: String
        var acuity: Int
        var ceiling: Double
        var discount: Double
        var currency: String
        var region: String
        var score: Double
        var ward: String
        var specialty: String
        var payer: String
        var status: StrictDisclosureLedgerStatus

        init(code: String, name: String, acuity: Int, ceiling: Double, discount: Double, currency: String, region: String, score: Double, ward: String, specialty: String, payer: String, status: StrictDisclosureLedgerStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.ceiling = ceiling
            self.discount = discount
            self.currency = currency
            self.region = region
            self.score = score
            self.ward = ward
            self.specialty = specialty
            self.payer = payer
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

        func canMoveTo(_ next: StrictDisclosureLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictDisclosureLedgerStatus.validated
            case .validated:
                return next == StrictDisclosureLedgerStatus.retired
            case .published:
                return next == StrictDisclosureLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictDisclosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict disclosure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(acuity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> StrictDisclosureLedger {
            return StrictDisclosureLedger(
                code: code,
                name: name,
                acuity: acuity,
                ceiling: ceiling,
                discount: discount,
                currency: currency,
                region: region,
                score: score,
                ward: ward,
                specialty: specialty,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict disclosure ledger in status created.
    static func newStrictDisclosureLedger(_ code: String, name: String) -> StrictDisclosureLedger {
        return StrictDisclosureLedger(
            code: code,
            name: name,
            acuity: 0,
            ceiling: 0.0,
            discount: 0.0,
            currency: "",
            region: "",
            score: 0.0,
            ward: "",
            specialty: "",
            payer: "",
            status: StrictDisclosureLedgerStatus.created
        )
    }
}
