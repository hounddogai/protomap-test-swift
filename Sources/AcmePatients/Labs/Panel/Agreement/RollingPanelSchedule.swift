import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling panel schedule is in its life cycle.
    enum RollingPanelScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rolling panel schedule, with what the planners need to act on it.
    final class RollingPanelSchedule {
        var code: String
        var label: String
        var ownerID: String
        var dosageMg: Double
        var threshold: Double
        var status: RollingPanelScheduleStatus

        init(code: String, label: String, ownerID: String, dosageMg: Double, threshold: Double, status: RollingPanelScheduleStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.threshold = threshold
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

        func canMoveTo(_ next: RollingPanelScheduleStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingPanelScheduleStatus.warming
            case .warming:
                return next == RollingPanelScheduleStatus.ready
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingPanelScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling panel schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling panel schedule") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((threshold - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> RollingPanelSchedule {
            return RollingPanelSchedule(
                code: code,
                label: label,
                ownerID: ownerID,
                dosageMg: dosageMg,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling panel schedule in status idle.
    static func newRollingPanelSchedule(_ code: String, label: String) -> RollingPanelSchedule {
        return RollingPanelSchedule(
            code: code,
            label: label,
            ownerID: "",
            dosageMg: 0.0,
            threshold: 0.0,
            status: RollingPanelScheduleStatus.idle
        )
    }
}
