import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory snapshot is in its life cycle.
    enum InventorySnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A inventory snapshot. Its code is unique within a tenant.
    final class InventorySnapshot {
        var code: String
        var label: String
        var ownerID: String
        var attempts: Int
        var facility: String
        var diagnosisCode: String
        var patientRef: String
        var status: InventorySnapshotStatus

        init(code: String, label: String, ownerID: String, attempts: Int, facility: String, diagnosisCode: String, patientRef: String, status: InventorySnapshotStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.attempts = attempts
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
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

        func canMoveTo(_ next: InventorySnapshotStatus) -> Bool {
            switch status {
            case .idle:
                return next == InventorySnapshotStatus.warming
            case .warming:
                return next == InventorySnapshotStatus.ready || next == InventorySnapshotStatus.stopped
            case .ready:
                return next == InventorySnapshotStatus.draining || next == InventorySnapshotStatus.stopped
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

        func moveTo(_ next: InventorySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("inventory snapshot") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> InventorySnapshot {
            return InventorySnapshot(
                code: code,
                label: label,
                ownerID: ownerID,
                attempts: attempts,
                facility: facility,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a inventory snapshot in status idle.
    static func newInventorySnapshot(_ code: String, label: String) -> InventorySnapshot {
        return InventorySnapshot(
            code: code,
            label: label,
            ownerID: "",
            attempts: 0,
            facility: "",
            diagnosisCode: "",
            patientRef: "",
            status: InventorySnapshotStatus.idle
        )
    }
}
