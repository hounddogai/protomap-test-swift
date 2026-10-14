import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched formulary reservation is in its life cycle.
    enum BatchedFormularyReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched formulary reservation as the formulary team keeps it.
    final class BatchedFormularyReservation {
        var code: String
        var name: String
        var weight: Double
        var attempts: Int
        var checksum: String
        var segment: String
        var batchSize: Int
        var status: BatchedFormularyReservationStatus

        init(code: String, name: String, weight: Double, attempts: Int, checksum: String, segment: String, batchSize: Int, status: BatchedFormularyReservationStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.attempts = attempts
            self.checksum = checksum
            self.segment = segment
            self.batchSize = batchSize
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

        func canMoveTo(_ next: BatchedFormularyReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BatchedFormularyReservationStatus.resolved || next == BatchedFormularyReservationStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedFormularyReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedFormularyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched formulary reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched formulary reservation") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(attempts) - weight) * 100).rounded() / 100
        }

        func copyValue() -> BatchedFormularyReservation {
            return BatchedFormularyReservation(
                code: code,
                name: name,
                weight: weight,
                attempts: attempts,
                checksum: checksum,
                segment: segment,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched formulary reservation in status open.
    static func newBatchedFormularyReservation(_ code: String, name: String) -> BatchedFormularyReservation {
        return BatchedFormularyReservation(
            code: code,
            name: name,
            weight: 0.0,
            attempts: 0,
            checksum: "",
            segment: "",
            batchSize: 0,
            status: BatchedFormularyReservationStatus.`open`
        )
    }
}
