import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist reservation is in its life cycle.
    enum WorklistReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a worklist reservation and its current status.
    final class WorklistReservation {
        var code: String
        var title: String
        var retries: Int
        var ratio: Double
        var visitMinutes: Int
        var refills: Int
        var specialty: String
        var source: String
        var maximum: Double
        var priority: Int
        var amount: Double
        var status: WorklistReservationStatus

        init(code: String, title: String, retries: Int, ratio: Double, visitMinutes: Int, refills: Int, specialty: String, source: String, maximum: Double, priority: Int, amount: Double, status: WorklistReservationStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.refills = refills
            self.specialty = specialty
            self.source = source
            self.maximum = maximum
            self.priority = priority
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistReservationStatus.withdrawn
            case .approved:
                return next == WorklistReservationStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: WorklistReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveVolume() -> Double {
            return ((maximum - amount) * 100).rounded() / 100
        }

        func copyValue() -> WorklistReservation {
            return WorklistReservation(
                code: code,
                title: title,
                retries: retries,
                ratio: ratio,
                visitMinutes: visitMinutes,
                refills: refills,
                specialty: specialty,
                source: source,
                maximum: maximum,
                priority: priority,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a worklist reservation in status proposed.
    static func newWorklistReservation(_ code: String, title: String) -> WorklistReservation {
        return WorklistReservation(
            code: code,
            title: title,
            retries: 0,
            ratio: 0.0,
            visitMinutes: 0,
            refills: 0,
            specialty: "",
            source: "",
            maximum: 0.0,
            priority: 0,
            amount: 0.0,
            status: WorklistReservationStatus.proposed
        )
    }
}
