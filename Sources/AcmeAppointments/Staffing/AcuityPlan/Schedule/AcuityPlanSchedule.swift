import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan schedule is in its life cycle.
    enum AcuityPlanScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a acuity plan schedule and its current status.
    final class AcuityPlanSchedule {
        var code: String
        var label: String
        var margin: Double
        var ceiling: Double
        var externalRef: String
        var status: AcuityPlanScheduleStatus

        init(code: String, label: String, margin: Double, ceiling: Double, externalRef: String, status: AcuityPlanScheduleStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.ceiling = ceiling
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AcuityPlanScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AcuityPlanScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("acuity plan schedule") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((margin + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanSchedule {
            return AcuityPlanSchedule(
                code: code,
                label: label,
                margin: margin,
                ceiling: ceiling,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a acuity plan schedule in status requested.
    static func newAcuityPlanSchedule(_ code: String, label: String) -> AcuityPlanSchedule {
        return AcuityPlanSchedule(
            code: code,
            label: label,
            margin: 0.0,
            ceiling: 0.0,
            externalRef: "",
            status: AcuityPlanScheduleStatus.requested
        )
    }
}
