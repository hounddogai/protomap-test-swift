import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen ledger is in its life cycle.
    enum AdaptiveSpecimenLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive specimen ledger, with what the planners need to act on it.
    final class AdaptiveSpecimenLedger {
        var code: String
        var label: String
        var country: String
        var allergy: String
        var notes: String
        var updatedAt: Int
        var amount: Double
        var payer: String
        var locale: String
        var status: AdaptiveSpecimenLedgerStatus

        init(code: String, label: String, country: String, allergy: String, notes: String, updatedAt: Int, amount: Double, payer: String, locale: String, status: AdaptiveSpecimenLedgerStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.allergy = allergy
            self.notes = notes
            self.updatedAt = updatedAt
            self.amount = amount
            self.payer = payer
            self.locale = locale
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

        func canMoveTo(_ next: AdaptiveSpecimenLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveSpecimenLedgerStatus.rejected || next == AdaptiveSpecimenLedgerStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveSpecimenLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedVolume() -> Double {
            return ((amount + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSpecimenLedger {
            return AdaptiveSpecimenLedger(
                code: code,
                label: label,
                country: country,
                allergy: allergy,
                notes: notes,
                updatedAt: updatedAt,
                amount: amount,
                payer: payer,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive specimen ledger in status proposed.
    static func newAdaptiveSpecimenLedger(_ code: String, label: String) -> AdaptiveSpecimenLedger {
        return AdaptiveSpecimenLedger(
            code: code,
            label: label,
            country: "",
            allergy: "",
            notes: "",
            updatedAt: 0,
            amount: 0.0,
            payer: "",
            locale: "",
            status: AdaptiveSpecimenLedgerStatus.proposed
        )
    }
}
