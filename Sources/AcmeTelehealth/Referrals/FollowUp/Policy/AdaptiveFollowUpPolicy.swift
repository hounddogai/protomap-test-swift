import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive follow up policy is in its life cycle.
    enum AdaptiveFollowUpPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive follow up policy and its current status.
    final class AdaptiveFollowUpPolicy {
        var code: String
        var label: String
        var margin: Double
        var visible: Bool
        var copay: Double
        var status: AdaptiveFollowUpPolicyStatus

        init(code: String, label: String, margin: Double, visible: Bool, copay: Double, status: AdaptiveFollowUpPolicyStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.visible = visible
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveFollowUpPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveFollowUpPolicyStatus.validated
            case .validated:
                return next == AdaptiveFollowUpPolicyStatus.published || next == AdaptiveFollowUpPolicyStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AdaptiveFollowUpPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive follow up policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive follow up policy") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((copay + margin) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveFollowUpPolicy {
            return AdaptiveFollowUpPolicy(
                code: code,
                label: label,
                margin: margin,
                visible: visible,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive follow up policy in status created.
    static func newAdaptiveFollowUpPolicy(_ code: String, label: String) -> AdaptiveFollowUpPolicy {
        return AdaptiveFollowUpPolicy(
            code: code,
            label: label,
            margin: 0.0,
            visible: false,
            copay: 0.0,
            status: AdaptiveFollowUpPolicyStatus.created
        )
    }
}
