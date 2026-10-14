import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped recall reservation is in its life cycle.
    enum CappedRecallReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a capped recall reservation and its current status.
    final class CappedRecallReservation {
        var code: String
        var name: String
        var checksum: String
        var procedureCode: String
        var threshold: Double
        var ratio: Double
        var country: String
        var status: CappedRecallReservationStatus

        init(code: String, name: String, checksum: String, procedureCode: String, threshold: Double, ratio: Double, country: String, status: CappedRecallReservationStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.ratio = ratio
            self.country = country
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

        func canMoveTo(_ next: CappedRecallReservationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedRecallReservationStatus.completed
            case .completed:
                return next == CappedRecallReservationStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedRecallReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped recall reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveLoad() -> Double {
            return (ratio * threshold * 100).rounded() / 100
        }

        func copyValue() -> CappedRecallReservation {
            return CappedRecallReservation(
                code: code,
                name: name,
                checksum: checksum,
                procedureCode: procedureCode,
                threshold: threshold,
                ratio: ratio,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped recall reservation in status planned.
    static func newCappedRecallReservation(_ code: String, name: String) -> CappedRecallReservation {
        return CappedRecallReservation(
            code: code,
            name: name,
            checksum: "",
            procedureCode: "",
            threshold: 0.0,
            ratio: 0.0,
            country: "",
            status: CappedRecallReservationStatus.planned
        )
    }
}
