import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary census checkpoint is in its life cycle.
    enum PrimaryCensusCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a primary census checkpoint and its current status.
    final class PrimaryCensusCheckpoint {
        var code: String
        var title: String
        var copay: Double
        var segment: String
        var dosageMg: Double
        var capacity: Int
        var budget: Double
        var rate: Double
        var batchSize: Int
        var status: PrimaryCensusCheckpointStatus

        init(code: String, title: String, copay: Double, segment: String, dosageMg: Double, capacity: Int, budget: Double, rate: Double, batchSize: Int, status: PrimaryCensusCheckpointStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.segment = segment
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.budget = budget
            self.rate = rate
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PrimaryCensusCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimaryCensusCheckpointStatus.rejected || next == PrimaryCensusCheckpointStatus.withdrawn
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

        func moveTo(_ next: PrimaryCensusCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary census checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((Double(batchSize) - budget) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCensusCheckpoint {
            return PrimaryCensusCheckpoint(
                code: code,
                title: title,
                copay: copay,
                segment: segment,
                dosageMg: dosageMg,
                capacity: capacity,
                budget: budget,
                rate: rate,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary census checkpoint in status proposed.
    static func newPrimaryCensusCheckpoint(_ code: String, title: String) -> PrimaryCensusCheckpoint {
        return PrimaryCensusCheckpoint(
            code: code,
            title: title,
            copay: 0.0,
            segment: "",
            dosageMg: 0.0,
            capacity: 0,
            budget: 0.0,
            rate: 0.0,
            batchSize: 0,
            status: PrimaryCensusCheckpointStatus.proposed
        )
    }
}
