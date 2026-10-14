import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped claim reservation is in its life cycle.
    enum CappedClaimReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One capped claim reservation, with what the planners need to act on it.
    final class CappedClaimReservation {
        var code: String
        var label: String
        var currency: String
        var payer: String
        var amount: Double
        var diagnosisCode: String
        var checksum: String
        var locale: String
        var ceiling: Double
        var encounterID: String
        var status: CappedClaimReservationStatus

        init(code: String, label: String, currency: String, payer: String, amount: Double, diagnosisCode: String, checksum: String, locale: String, ceiling: Double, encounterID: String, status: CappedClaimReservationStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.payer = payer
            self.amount = amount
            self.diagnosisCode = diagnosisCode
            self.checksum = checksum
            self.locale = locale
            self.ceiling = ceiling
            self.encounterID = encounterID
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

        func canMoveTo(_ next: CappedClaimReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CappedClaimReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped claim reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped claim reservation") \(code)"
        }

        func netLoad() -> Double {
            return (amount * ceiling * 100).rounded() / 100
        }

        func copyValue() -> CappedClaimReservation {
            return CappedClaimReservation(
                code: code,
                label: label,
                currency: currency,
                payer: payer,
                amount: amount,
                diagnosisCode: diagnosisCode,
                checksum: checksum,
                locale: locale,
                ceiling: ceiling,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a capped claim reservation in status planned.
    static func newCappedClaimReservation(_ code: String, label: String) -> CappedClaimReservation {
        return CappedClaimReservation(
            code: code,
            label: label,
            currency: "",
            payer: "",
            amount: 0.0,
            diagnosisCode: "",
            checksum: "",
            locale: "",
            ceiling: 0.0,
            encounterID: "",
            status: CappedClaimReservationStatus.planned
        )
    }
}
