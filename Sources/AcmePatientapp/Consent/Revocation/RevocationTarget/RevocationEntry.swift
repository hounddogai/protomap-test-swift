import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation entry is in its life cycle.
    enum RevocationEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One revocation entry, with what the planners need to act on it.
    final class RevocationEntry {
        var code: String
        var label: String
        var quantity: Int
        var locale: String
        var acuity: Int
        var discount: Double
        var patientRef: String
        var rate: Double
        var ward: String
        var copay: Double
        var dosageMg: Double
        var status: RevocationEntryStatus

        init(code: String, label: String, quantity: Int, locale: String, acuity: Int, discount: Double, patientRef: String, rate: Double, ward: String, copay: Double, dosageMg: Double, status: RevocationEntryStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.locale = locale
            self.acuity = acuity
            self.discount = discount
            self.patientRef = patientRef
            self.rate = rate
            self.ward = ward
            self.copay = copay
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == RevocationEntryStatus.warming || next == RevocationEntryStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RevocationEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return (dosageMg * discount * 100).rounded() / 100
        }

        func copyValue() -> RevocationEntry {
            return RevocationEntry(
                code: code,
                label: label,
                quantity: quantity,
                locale: locale,
                acuity: acuity,
                discount: discount,
                patientRef: patientRef,
                rate: rate,
                ward: ward,
                copay: copay,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a revocation entry in status idle.
    static func newRevocationEntry(_ code: String, label: String) -> RevocationEntry {
        return RevocationEntry(
            code: code,
            label: label,
            quantity: 0,
            locale: "",
            acuity: 0,
            discount: 0.0,
            patientRef: "",
            rate: 0.0,
            ward: "",
            copay: 0.0,
            dosageMg: 0.0,
            status: RevocationEntryStatus.idle
        )
    }
}
