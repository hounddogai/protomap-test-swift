import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending read reservation is in its life cycle.
    enum PendingReadReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a pending read reservation and its current status.
    final class PendingReadReservation {
        var code: String
        var label: String
        var specialty: String
        var allergy: String
        var ratio: Double
        var updatedAt: Int
        var pinned: Bool
        var status: PendingReadReservationStatus

        init(code: String, label: String, specialty: String, allergy: String, ratio: Double, updatedAt: Int, pinned: Bool, status: PendingReadReservationStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.allergy = allergy
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.pinned = pinned
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

        func canMoveTo(_ next: PendingReadReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PendingReadReservationStatus.stopped
            case .ready:
                return next == PendingReadReservationStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingReadReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending read reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((ratio + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingReadReservation {
            return PendingReadReservation(
                code: code,
                label: label,
                specialty: specialty,
                allergy: allergy,
                ratio: ratio,
                updatedAt: updatedAt,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending read reservation in status idle.
    static func newPendingReadReservation(_ code: String, label: String) -> PendingReadReservation {
        return PendingReadReservation(
            code: code,
            label: label,
            specialty: "",
            allergy: "",
            ratio: 0.0,
            updatedAt: 0,
            pinned: false,
            status: PendingReadReservationStatus.idle
        )
    }
}
