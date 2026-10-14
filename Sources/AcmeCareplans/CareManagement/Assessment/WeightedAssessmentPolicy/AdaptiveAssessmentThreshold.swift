import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive assessment threshold is in its life cycle.
    enum AdaptiveAssessmentThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive assessment threshold as the assessment team keeps it.
    final class AdaptiveAssessmentThreshold {
        var code: String
        var title: String
        var channel: String
        var copay: Double
        var updatedAt: Int
        var status: AdaptiveAssessmentThresholdStatus

        init(code: String, title: String, channel: String, copay: Double, updatedAt: Int, status: AdaptiveAssessmentThresholdStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.copay = copay
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: AdaptiveAssessmentThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveAssessmentThresholdStatus.approved || next == AdaptiveAssessmentThresholdStatus.rejected
            case .approved:
                return next == AdaptiveAssessmentThresholdStatus.rejected || next == AdaptiveAssessmentThresholdStatus.withdrawn
            case .rejected:
                return next == AdaptiveAssessmentThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAssessmentThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive assessment threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive assessment threshold") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(updatedAt) * copay * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAssessmentThreshold {
            return AdaptiveAssessmentThreshold(
                code: code,
                title: title,
                channel: channel,
                copay: copay,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive assessment threshold in status proposed.
    static func newAdaptiveAssessmentThreshold(_ code: String, title: String) -> AdaptiveAssessmentThreshold {
        return AdaptiveAssessmentThreshold(
            code: code,
            title: title,
            channel: "",
            copay: 0.0,
            updatedAt: 0,
            status: AdaptiveAssessmentThresholdStatus.proposed
        )
    }
}
