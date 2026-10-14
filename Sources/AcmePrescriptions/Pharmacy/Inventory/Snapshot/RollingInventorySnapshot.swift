import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling inventory snapshot is in its life cycle.
    enum RollingInventorySnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling inventory snapshot. Its code is unique within a tenant.
    final class RollingInventorySnapshot {
        var code: String
        var title: String
        var expiresAt: Int
        var facility: String
        var minimum: Double
        var dosageMg: Double
        var name: String
        var maximum: Double
        var encounterID: String
        var copay: Double
        var segment: String
        var status: RollingInventorySnapshotStatus

        init(code: String, title: String, expiresAt: Int, facility: String, minimum: Double, dosageMg: Double, name: String, maximum: Double, encounterID: String, copay: Double, segment: String, status: RollingInventorySnapshotStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.facility = facility
            self.minimum = minimum
            self.dosageMg = dosageMg
            self.name = name
            self.maximum = maximum
            self.encounterID = encounterID
            self.copay = copay
            self.segment = segment
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

        func canMoveTo(_ next: RollingInventorySnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingInventorySnapshotStatus.completed || next == RollingInventorySnapshotStatus.cancelled
            case .scheduled:
                return next == RollingInventorySnapshotStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingInventorySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling inventory snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return (dosageMg * minimum * 100).rounded() / 100
        }

        func copyValue() -> RollingInventorySnapshot {
            return RollingInventorySnapshot(
                code: code,
                title: title,
                expiresAt: expiresAt,
                facility: facility,
                minimum: minimum,
                dosageMg: dosageMg,
                name: name,
                maximum: maximum,
                encounterID: encounterID,
                copay: copay,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling inventory snapshot in status planned.
    static func newRollingInventorySnapshot(_ code: String, title: String) -> RollingInventorySnapshot {
        return RollingInventorySnapshot(
            code: code,
            title: title,
            expiresAt: 0,
            facility: "",
            minimum: 0.0,
            dosageMg: 0.0,
            name: "",
            maximum: 0.0,
            encounterID: "",
            copay: 0.0,
            segment: "",
            status: RollingInventorySnapshotStatus.planned
        )
    }
}
