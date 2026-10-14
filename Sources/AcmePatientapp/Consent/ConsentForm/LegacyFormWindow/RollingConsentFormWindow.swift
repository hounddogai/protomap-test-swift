import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form window is in its life cycle.
    enum RollingConsentFormWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a rolling consent form window and its current status.
    final class RollingConsentFormWindow {
        var code: String
        var title: String
        var visitMinutes: Int
        var clinicianID: String
        var graceDays: Int
        var specialty: String
        var maximum: Double
        var checksum: String
        var priority: Int
        var acuity: Int
        var status: RollingConsentFormWindowStatus

        init(code: String, title: String, visitMinutes: Int, clinicianID: String, graceDays: Int, specialty: String, maximum: Double, checksum: String, priority: Int, acuity: Int, status: RollingConsentFormWindowStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.specialty = specialty
            self.maximum = maximum
            self.checksum = checksum
            self.priority = priority
            self.acuity = acuity
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

        func canMoveTo(_ next: RollingConsentFormWindowStatus) -> Bool {
            switch status {
            case .planned:
                return next == RollingConsentFormWindowStatus.inProgress || next == RollingConsentFormWindowStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RollingConsentFormWindowStatus.cancelled
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

        func moveTo(_ next: RollingConsentFormWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling consent form window") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(priority) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingConsentFormWindow {
            return RollingConsentFormWindow(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                clinicianID: clinicianID,
                graceDays: graceDays,
                specialty: specialty,
                maximum: maximum,
                checksum: checksum,
                priority: priority,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling consent form window in status planned.
    static func newRollingConsentFormWindow(_ code: String, title: String) -> RollingConsentFormWindow {
        return RollingConsentFormWindow(
            code: code,
            title: title,
            visitMinutes: 0,
            clinicianID: "",
            graceDays: 0,
            specialty: "",
            maximum: 0.0,
            checksum: "",
            priority: 0,
            acuity: 0,
            status: RollingConsentFormWindowStatus.planned
        )
    }
}
