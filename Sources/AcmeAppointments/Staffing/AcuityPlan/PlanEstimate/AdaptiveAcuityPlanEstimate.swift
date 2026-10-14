import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive acuity plan estimate is in its life cycle.
    enum AdaptiveAcuityPlanEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive acuity plan estimate as the acuity plan team keeps it.
    final class AdaptiveAcuityPlanEstimate {
        var code: String
        var label: String
        var channel: String
        var limit: Int
        var patientRef: String
        var refills: Int
        var status: AdaptiveAcuityPlanEstimateStatus

        init(code: String, label: String, channel: String, limit: Int, patientRef: String, refills: Int, status: AdaptiveAcuityPlanEstimateStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.limit = limit
            self.patientRef = patientRef
            self.refills = refills
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

        func canMoveTo(_ next: AdaptiveAcuityPlanEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == AdaptiveAcuityPlanEstimateStatus.completed
            case .scheduled:
                return next == AdaptiveAcuityPlanEstimateStatus.inProgress || next == AdaptiveAcuityPlanEstimateStatus.cancelled
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

        func moveTo(_ next: AdaptiveAcuityPlanEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive acuity plan estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return ((Double(limit) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAcuityPlanEstimate {
            return AdaptiveAcuityPlanEstimate(
                code: code,
                label: label,
                channel: channel,
                limit: limit,
                patientRef: patientRef,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive acuity plan estimate in status planned.
    static func newAdaptiveAcuityPlanEstimate(_ code: String, label: String) -> AdaptiveAcuityPlanEstimate {
        return AdaptiveAcuityPlanEstimate(
            code: code,
            label: label,
            channel: "",
            limit: 0,
            patientRef: "",
            refills: 0,
            status: AdaptiveAcuityPlanEstimateStatus.planned
        )
    }
}
