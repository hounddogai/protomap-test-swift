import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap reservation is in its life cycle.
    enum CareGapReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care gap reservation and its current status.
    final class CareGapReservation {
        var code: String
        var name: String
        var attempts: Int
        var unit: String
        var pinned: Bool
        var batchSize: Int
        var status: CareGapReservationStatus

        init(code: String, name: String, attempts: Int, unit: String, pinned: Bool, batchSize: Int, status: CareGapReservationStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.unit = unit
            self.pinned = pinned
            self.batchSize = batchSize
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

        func canMoveTo(_ next: CareGapReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == CareGapReservationStatus.queued || next == CareGapReservationStatus.failed
            case .queued:
                return next == CareGapReservationStatus.running || next == CareGapReservationStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CareGapReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(attempts) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapReservation {
            return CareGapReservation(
                code: code,
                name: name,
                attempts: attempts,
                unit: unit,
                pinned: pinned,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a care gap reservation in status new.
    static func newCareGapReservation(_ code: String, name: String) -> CareGapReservation {
        return CareGapReservation(
            code: code,
            name: name,
            attempts: 0,
            unit: "",
            pinned: false,
            batchSize: 0,
            status: CareGapReservationStatus.new
        )
    }
}
