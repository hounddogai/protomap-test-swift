import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen checkpoint is in its life cycle.
    enum SpecimenCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One specimen checkpoint, with what the planners need to act on it.
    final class SpecimenCheckpoint {
        var code: String
        var label: String
        var priority: Int
        var updatedAt: Int
        var externalRef: String
        var facility: String
        var visible: Bool
        var category: String
        var status: SpecimenCheckpointStatus

        init(code: String, label: String, priority: Int, updatedAt: Int, externalRef: String, facility: String, visible: Bool, category: String, status: SpecimenCheckpointStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.facility = facility
            self.visible = visible
            self.category = category
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

        func canMoveTo(_ next: SpecimenCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == SpecimenCheckpointStatus.stopped
            case .warming:
                return next == SpecimenCheckpointStatus.draining || next == SpecimenCheckpointStatus.stopped
            case .ready:
                return next == SpecimenCheckpointStatus.draining || next == SpecimenCheckpointStatus.stopped
            case .draining:
                return next == SpecimenCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("specimen checkpoint") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(updatedAt) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenCheckpoint {
            return SpecimenCheckpoint(
                code: code,
                label: label,
                priority: priority,
                updatedAt: updatedAt,
                externalRef: externalRef,
                facility: facility,
                visible: visible,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a specimen checkpoint in status idle.
    static func newSpecimenCheckpoint(_ code: String, label: String) -> SpecimenCheckpoint {
        return SpecimenCheckpoint(
            code: code,
            label: label,
            priority: 0,
            updatedAt: 0,
            externalRef: "",
            facility: "",
            visible: false,
            category: "",
            status: SpecimenCheckpointStatus.idle
        )
    }
}
