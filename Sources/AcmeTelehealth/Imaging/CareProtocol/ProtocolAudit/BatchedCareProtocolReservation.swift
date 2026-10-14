import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched care protocol reservation is in its life cycle.
    enum BatchedCareProtocolReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched care protocol reservation and its current status.
    final class BatchedCareProtocolReservation {
        var code: String
        var name: String
        var updatedAt: Int
        var specialty: String
        var reviewer: String
        var weight: Double
        var amount: Double
        var visible: Bool
        var status: BatchedCareProtocolReservationStatus

        init(code: String, name: String, updatedAt: Int, specialty: String, reviewer: String, weight: Double, amount: Double, visible: Bool, status: BatchedCareProtocolReservationStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.reviewer = reviewer
            self.weight = weight
            self.amount = amount
            self.visible = visible
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

        func canMoveTo(_ next: BatchedCareProtocolReservationStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedCareProtocolReservationStatus.stopped
            case .warming:
                return next == BatchedCareProtocolReservationStatus.ready
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == BatchedCareProtocolReservationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCareProtocolReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care protocol reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched care protocol reservation") \(code)"
        }

        func weightedValue() -> Double {
            return (amount * weight * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareProtocolReservation {
            return BatchedCareProtocolReservation(
                code: code,
                name: name,
                updatedAt: updatedAt,
                specialty: specialty,
                reviewer: reviewer,
                weight: weight,
                amount: amount,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched care protocol reservation in status idle.
    static func newBatchedCareProtocolReservation(_ code: String, name: String) -> BatchedCareProtocolReservation {
        return BatchedCareProtocolReservation(
            code: code,
            name: name,
            updatedAt: 0,
            specialty: "",
            reviewer: "",
            weight: 0.0,
            amount: 0.0,
            visible: false,
            status: BatchedCareProtocolReservationStatus.idle
        )
    }
}
