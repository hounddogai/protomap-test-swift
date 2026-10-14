import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling study segment is in its life cycle.
    enum RollingStudySegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling study segment. Its code is unique within a tenant.
    final class RollingStudySegment {
        var code: String
        var name: String
        var patientRef: String
        var expiresAt: Int
        var payer: String
        var label: String
        var status: RollingStudySegmentStatus

        init(code: String, name: String, patientRef: String, expiresAt: Int, payer: String, label: String, status: RollingStudySegmentStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.expiresAt = expiresAt
            self.payer = payer
            self.label = label
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

        func canMoveTo(_ next: RollingStudySegmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RollingStudySegmentStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: RollingStudySegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling study segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> RollingStudySegment {
            return RollingStudySegment(
                code: code,
                name: name,
                patientRef: patientRef,
                expiresAt: expiresAt,
                payer: payer,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling study segment in status planned.
    static func newRollingStudySegment(_ code: String, name: String) -> RollingStudySegment {
        return RollingStudySegment(
            code: code,
            name: name,
            patientRef: "",
            expiresAt: 0,
            payer: "",
            label: "",
            status: RollingStudySegmentStatus.planned
        )
    }
}
