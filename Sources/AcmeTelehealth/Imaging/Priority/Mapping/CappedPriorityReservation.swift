import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped priority reservation is in its life cycle.
    enum CappedPriorityReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped priority reservation. Its code is unique within a tenant.
    final class CappedPriorityReservation {
        var code: String
        var label: String
        var description: String
        var refills: Int
        var expiresAt: Int
        var priority: Int
        var attempts: Int
        var notes: String
        var dosageMg: Double
        var status: CappedPriorityReservationStatus

        init(code: String, label: String, description: String, refills: Int, expiresAt: Int, priority: Int, attempts: Int, notes: String, dosageMg: Double, status: CappedPriorityReservationStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.refills = refills
            self.expiresAt = expiresAt
            self.priority = priority
            self.attempts = attempts
            self.notes = notes
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: CappedPriorityReservationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedPriorityReservationStatus.running || next == CappedPriorityReservationStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CappedPriorityReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedPriorityReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped priority reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("capped priority reservation") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(refills) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CappedPriorityReservation {
            return CappedPriorityReservation(
                code: code,
                label: label,
                description: description,
                refills: refills,
                expiresAt: expiresAt,
                priority: priority,
                attempts: attempts,
                notes: notes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped priority reservation in status new.
    static func newCappedPriorityReservation(_ code: String, label: String) -> CappedPriorityReservation {
        return CappedPriorityReservation(
            code: code,
            label: label,
            description: "",
            refills: 0,
            expiresAt: 0,
            priority: 0,
            attempts: 0,
            notes: "",
            dosageMg: 0.0,
            status: CappedPriorityReservationStatus.new
        )
    }
}
