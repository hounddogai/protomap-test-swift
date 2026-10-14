import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default shift reservation is in its life cycle.
    enum DefaultShiftReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A default shift reservation as the shift team keeps it.
    final class DefaultShiftReservation {
        var code: String
        var title: String
        var batchSize: Int
        var cost: Double
        var durationMinutes: Int
        var capacity: Int
        var encounterID: String
        var name: String
        var amount: Double
        var status: DefaultShiftReservationStatus

        init(code: String, title: String, batchSize: Int, cost: Double, durationMinutes: Int, capacity: Int, encounterID: String, name: String, amount: Double, status: DefaultShiftReservationStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.cost = cost
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.encounterID = encounterID
            self.name = name
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultShiftReservationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultShiftReservationStatus.resolved || next == DefaultShiftReservationStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DefaultShiftReservationStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DefaultShiftReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default shift reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedLoad() -> Double {
            return ((cost - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultShiftReservation {
            return DefaultShiftReservation(
                code: code,
                title: title,
                batchSize: batchSize,
                cost: cost,
                durationMinutes: durationMinutes,
                capacity: capacity,
                encounterID: encounterID,
                name: name,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default shift reservation in status open.
    static func newDefaultShiftReservation(_ code: String, title: String) -> DefaultShiftReservation {
        return DefaultShiftReservation(
            code: code,
            title: title,
            batchSize: 0,
            cost: 0.0,
            durationMinutes: 0,
            capacity: 0,
            encounterID: "",
            name: "",
            amount: 0.0,
            status: DefaultShiftReservationStatus.`open`
        )
    }
}
