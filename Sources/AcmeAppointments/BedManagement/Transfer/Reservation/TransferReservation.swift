import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer reservation is in its life cycle.
    enum TransferReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One transfer reservation, with what the planners need to act on it.
    final class TransferReservation {
        var code: String
        var label: String
        var country: String
        var diagnosisCode: String
        var name: String
        var patientRef: String
        var locale: String
        var cost: Double
        var attempts: Int
        var description: String
        var status: TransferReservationStatus

        init(code: String, label: String, country: String, diagnosisCode: String, name: String, patientRef: String, locale: String, cost: Double, attempts: Int, description: String, status: TransferReservationStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.name = name
            self.patientRef = patientRef
            self.locale = locale
            self.cost = cost
            self.attempts = attempts
            self.description = description
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

        func canMoveTo(_ next: TransferReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == TransferReservationStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == TransferReservationStatus.failed
            case .done:
                return next == TransferReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return (Double(attempts) * cost * 100).rounded() / 100
        }

        func copyValue() -> TransferReservation {
            return TransferReservation(
                code: code,
                label: label,
                country: country,
                diagnosisCode: diagnosisCode,
                name: name,
                patientRef: patientRef,
                locale: locale,
                cost: cost,
                attempts: attempts,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a transfer reservation in status new.
    static func newTransferReservation(_ code: String, label: String) -> TransferReservation {
        return TransferReservation(
            code: code,
            label: label,
            country: "",
            diagnosisCode: "",
            name: "",
            patientRef: "",
            locale: "",
            cost: 0.0,
            attempts: 0,
            description: "",
            status: TransferReservationStatus.new
        )
    }
}
