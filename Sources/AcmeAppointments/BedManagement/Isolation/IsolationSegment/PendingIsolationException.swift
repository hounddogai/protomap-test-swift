import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending isolation exception is in its life cycle.
    enum PendingIsolationExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending isolation exception and its current status.
    final class PendingIsolationException {
        var code: String
        var label: String
        var clinicianID: String
        var encounterID: String
        var pinned: Bool
        var margin: Double
        var retries: Int
        var status: PendingIsolationExceptionStatus

        init(code: String, label: String, clinicianID: String, encounterID: String, pinned: Bool, margin: Double, retries: Int, status: PendingIsolationExceptionStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.encounterID = encounterID
            self.pinned = pinned
            self.margin = margin
            self.retries = retries
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

        func canMoveTo(_ next: PendingIsolationExceptionStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingIsolationExceptionStatus.inProgress
            case .scheduled:
                return next == PendingIsolationExceptionStatus.inProgress || next == PendingIsolationExceptionStatus.completed
            case .inProgress:
                return next == PendingIsolationExceptionStatus.cancelled
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

        func moveTo(_ next: PendingIsolationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending isolation exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending isolation exception") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(retries) + margin) * 100).rounded() / 100
        }

        func copyValue() -> PendingIsolationException {
            return PendingIsolationException(
                code: code,
                label: label,
                clinicianID: clinicianID,
                encounterID: encounterID,
                pinned: pinned,
                margin: margin,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending isolation exception in status planned.
    static func newPendingIsolationException(_ code: String, label: String) -> PendingIsolationException {
        return PendingIsolationException(
            code: code,
            label: label,
            clinicianID: "",
            encounterID: "",
            pinned: false,
            margin: 0.0,
            retries: 0,
            status: PendingIsolationExceptionStatus.planned
        )
    }
}
