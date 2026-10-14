import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched specimen snapshot is in its life cycle.
    enum BatchedSpecimenSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched specimen snapshot, with what the planners need to act on it.
    final class BatchedSpecimenSnapshot {
        var code: String
        var name: String
        var active: Bool
        var copay: Double
        var dosageMg: Double
        var status: BatchedSpecimenSnapshotStatus

        init(code: String, name: String, active: Bool, copay: Double, dosageMg: Double, status: BatchedSpecimenSnapshotStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.copay = copay
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: BatchedSpecimenSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BatchedSpecimenSnapshotStatus.approved
            case .approved:
                return next == BatchedSpecimenSnapshotStatus.rejected || next == BatchedSpecimenSnapshotStatus.withdrawn
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

        func moveTo(_ next: BatchedSpecimenSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched specimen snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveVolume() -> Double {
            return ((copay + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSpecimenSnapshot {
            return BatchedSpecimenSnapshot(
                code: code,
                name: name,
                active: active,
                copay: copay,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched specimen snapshot in status proposed.
    static func newBatchedSpecimenSnapshot(_ code: String, name: String) -> BatchedSpecimenSnapshot {
        return BatchedSpecimenSnapshot(
            code: code,
            name: name,
            active: false,
            copay: 0.0,
            dosageMg: 0.0,
            status: BatchedSpecimenSnapshotStatus.proposed
        )
    }
}
