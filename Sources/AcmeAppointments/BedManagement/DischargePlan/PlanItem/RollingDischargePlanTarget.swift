import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling discharge plan target is in its life cycle.
    enum RollingDischargePlanTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling discharge plan target and its current status.
    final class RollingDischargePlanTarget {
        var code: String
        var title: String
        var label: String
        var specialty: String
        var bed: String
        var priority: Int
        var status: RollingDischargePlanTargetStatus

        init(code: String, title: String, label: String, specialty: String, bed: String, priority: Int, status: RollingDischargePlanTargetStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.specialty = specialty
            self.bed = bed
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingDischargePlanTargetStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingDischargePlanTargetStatus.done || next == RollingDischargePlanTargetStatus.failed
            case .queued:
                return next == RollingDischargePlanTargetStatus.running
            case .running:
                return next == RollingDischargePlanTargetStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingDischargePlanTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling discharge plan target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling discharge plan target") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> RollingDischargePlanTarget {
            return RollingDischargePlanTarget(
                code: code,
                title: title,
                label: label,
                specialty: specialty,
                bed: bed,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling discharge plan target in status new.
    static func newRollingDischargePlanTarget(_ code: String, title: String) -> RollingDischargePlanTarget {
        return RollingDischargePlanTarget(
            code: code,
            title: title,
            label: "",
            specialty: "",
            bed: "",
            priority: 0,
            status: RollingDischargePlanTargetStatus.new
        )
    }
}
