import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending program manifest is in its life cycle.
    enum PendingProgramManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending program manifest and its current status.
    final class PendingProgramManifest {
        var code: String
        var label: String
        var checksum: String
        var specialty: String
        var refills: Int
        var capacity: Int
        var reviewer: String
        var maximum: Double
        var active: Bool
        var status: PendingProgramManifestStatus

        init(code: String, label: String, checksum: String, specialty: String, refills: Int, capacity: Int, reviewer: String, maximum: Double, active: Bool, status: PendingProgramManifestStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.specialty = specialty
            self.refills = refills
            self.capacity = capacity
            self.reviewer = reviewer
            self.maximum = maximum
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingProgramManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == PendingProgramManifestStatus.closed
            case .pending:
                return next == PendingProgramManifestStatus.active
            case .active:
                return next == PendingProgramManifestStatus.suspended || next == PendingProgramManifestStatus.closed
            case .suspended:
                return next == PendingProgramManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingProgramManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending program manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netLoad() -> Double {
            return ((Double(capacity) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PendingProgramManifest {
            return PendingProgramManifest(
                code: code,
                label: label,
                checksum: checksum,
                specialty: specialty,
                refills: refills,
                capacity: capacity,
                reviewer: reviewer,
                maximum: maximum,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending program manifest in status draft.
    static func newPendingProgramManifest(_ code: String, label: String) -> PendingProgramManifest {
        return PendingProgramManifest(
            code: code,
            label: label,
            checksum: "",
            specialty: "",
            refills: 0,
            capacity: 0,
            reviewer: "",
            maximum: 0.0,
            active: false,
            status: PendingProgramManifestStatus.draft
        )
    }
}
