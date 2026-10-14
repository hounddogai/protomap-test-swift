import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default goal segment is in its life cycle.
    enum DefaultGoalSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default goal segment as the goal team keeps it.
    final class DefaultGoalSegment {
        var code: String
        var title: String
        var notes: String
        var facility: String
        var threshold: Double
        var dosageMg: Double
        var active: Bool
        var status: DefaultGoalSegmentStatus

        init(code: String, title: String, notes: String, facility: String, threshold: Double, dosageMg: Double, active: Bool, status: DefaultGoalSegmentStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.facility = facility
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.active = active
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

        func canMoveTo(_ next: DefaultGoalSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultGoalSegmentStatus.approved || next == DefaultGoalSegmentStatus.withdrawn
            case .approved:
                return next == DefaultGoalSegmentStatus.rejected || next == DefaultGoalSegmentStatus.withdrawn
            case .rejected:
                return next == DefaultGoalSegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultGoalSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default goal segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default goal segment") \(code)"
        }

        func adjustedVolume() -> Double {
            return (threshold * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> DefaultGoalSegment {
            return DefaultGoalSegment(
                code: code,
                title: title,
                notes: notes,
                facility: facility,
                threshold: threshold,
                dosageMg: dosageMg,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default goal segment in status proposed.
    static func newDefaultGoalSegment(_ code: String, title: String) -> DefaultGoalSegment {
        return DefaultGoalSegment(
            code: code,
            title: title,
            notes: "",
            facility: "",
            threshold: 0.0,
            dosageMg: 0.0,
            active: false,
            status: DefaultGoalSegmentStatus.proposed
        )
    }
}
