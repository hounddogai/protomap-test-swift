import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual denial ledger is in its life cycle.
    enum ManualDenialLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual denial ledger as the denial team keeps it.
    final class ManualDenialLedger {
        var code: String
        var name: String
        var facility: String
        var quantity: Int
        var margin: Double
        var ceiling: Double
        var discount: Double
        var contactEmail: String
        var weight: Double
        var patientRef: String
        var status: ManualDenialLedgerStatus

        init(code: String, name: String, facility: String, quantity: Int, margin: Double, ceiling: Double, discount: Double, contactEmail: String, weight: Double, patientRef: String, status: ManualDenialLedgerStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.quantity = quantity
            self.margin = margin
            self.ceiling = ceiling
            self.discount = discount
            self.contactEmail = contactEmail
            self.weight = weight
            self.patientRef = patientRef
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

        func canMoveTo(_ next: ManualDenialLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ManualDenialLedgerStatus.published || next == ManualDenialLedgerStatus.retired
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

        func moveTo(_ next: ManualDenialLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual denial ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual denial ledger") \(code)"
        }

        func weightedVolume() -> Double {
            return ((weight - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ManualDenialLedger {
            return ManualDenialLedger(
                code: code,
                name: name,
                facility: facility,
                quantity: quantity,
                margin: margin,
                ceiling: ceiling,
                discount: discount,
                contactEmail: contactEmail,
                weight: weight,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual denial ledger in status created.
    static func newManualDenialLedger(_ code: String, name: String) -> ManualDenialLedger {
        return ManualDenialLedger(
            code: code,
            name: name,
            facility: "",
            quantity: 0,
            margin: 0.0,
            ceiling: 0.0,
            discount: 0.0,
            contactEmail: "",
            weight: 0.0,
            patientRef: "",
            status: ManualDenialLedgerStatus.created
        )
    }
}
