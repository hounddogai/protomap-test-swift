import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall reservation is in its life cycle.
    enum RecallReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A recall reservation as the recall team keeps it.
    final class RecallReservation {
        var code: String
        var name: String
        var patientRef: String
        var rate: Double
        var region: String
        var segment: String
        var amount: Double
        var currency: String
        var durationMinutes: Int
        var label: String
        var ownerID: String
        var status: RecallReservationStatus

        init(code: String, name: String, patientRef: String, rate: Double, region: String, segment: String, amount: Double, currency: String, durationMinutes: Int, label: String, ownerID: String, status: RecallReservationStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.rate = rate
            self.region = region
            self.segment = segment
            self.amount = amount
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.label = label
            self.ownerID = ownerID
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

        func canMoveTo(_ next: RecallReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
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

        func moveTo(_ next: RecallReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("recall reservation") \(code)"
        }

        func adjustedValue() -> Double {
            return ((amount - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RecallReservation {
            return RecallReservation(
                code: code,
                name: name,
                patientRef: patientRef,
                rate: rate,
                region: region,
                segment: segment,
                amount: amount,
                currency: currency,
                durationMinutes: durationMinutes,
                label: label,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a recall reservation in status planned.
    static func newRecallReservation(_ code: String, name: String) -> RecallReservation {
        return RecallReservation(
            code: code,
            name: name,
            patientRef: "",
            rate: 0.0,
            region: "",
            segment: "",
            amount: 0.0,
            currency: "",
            durationMinutes: 0,
            label: "",
            ownerID: "",
            status: RecallReservationStatus.planned
        )
    }
}
