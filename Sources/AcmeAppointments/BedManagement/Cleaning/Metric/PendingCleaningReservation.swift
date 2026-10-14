import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending cleaning reservation is in its life cycle.
    enum PendingCleaningReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending cleaning reservation, with what the planners need to act on it.
    final class PendingCleaningReservation {
        var code: String
        var title: String
        var approved: Bool
        var segment: String
        var threshold: Double
        var ownerID: String
        var externalRef: String
        var specialty: String
        var clinicianID: String
        var capacity: Int
        var status: PendingCleaningReservationStatus

        init(code: String, title: String, approved: Bool, segment: String, threshold: Double, ownerID: String, externalRef: String, specialty: String, clinicianID: String, capacity: Int, status: PendingCleaningReservationStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.segment = segment
            self.threshold = threshold
            self.ownerID = ownerID
            self.externalRef = externalRef
            self.specialty = specialty
            self.clinicianID = clinicianID
            self.capacity = capacity
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

        func canMoveTo(_ next: PendingCleaningReservationStatus) -> Bool {
            switch status {
            case .idle:
                return next == PendingCleaningReservationStatus.warming
            case .warming:
                return next == PendingCleaningReservationStatus.draining || next == PendingCleaningReservationStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingCleaningReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending cleaning reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return ((Double(capacity) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingCleaningReservation {
            return PendingCleaningReservation(
                code: code,
                title: title,
                approved: approved,
                segment: segment,
                threshold: threshold,
                ownerID: ownerID,
                externalRef: externalRef,
                specialty: specialty,
                clinicianID: clinicianID,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending cleaning reservation in status idle.
    static func newPendingCleaningReservation(_ code: String, title: String) -> PendingCleaningReservation {
        return PendingCleaningReservation(
            code: code,
            title: title,
            approved: false,
            segment: "",
            threshold: 0.0,
            ownerID: "",
            externalRef: "",
            specialty: "",
            clinicianID: "",
            capacity: 0,
            status: PendingCleaningReservationStatus.idle
        )
    }
}
