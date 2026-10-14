import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled float pool policy is in its life cycle.
    enum ScheduledFloatPoolPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled float pool policy. Its code is unique within a tenant.
    final class ScheduledFloatPoolPolicy {
        var code: String
        var label: String
        var refills: Int
        var copay: Double
        var weight: Double
        var revision: Int
        var status: ScheduledFloatPoolPolicyStatus

        init(code: String, label: String, refills: Int, copay: Double, weight: Double, revision: Int, status: ScheduledFloatPoolPolicyStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.copay = copay
            self.weight = weight
            self.revision = revision
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

        func canMoveTo(_ next: ScheduledFloatPoolPolicyStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledFloatPoolPolicyStatus.granted
            case .granted:
                return next == ScheduledFloatPoolPolicyStatus.expired
            case .revoked:
                return next == ScheduledFloatPoolPolicyStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFloatPoolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled float pool policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("scheduled float pool policy") \(code)"
        }

        func adjustedValue() -> Double {
            return ((copay - weight) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFloatPoolPolicy {
            return ScheduledFloatPoolPolicy(
                code: code,
                label: label,
                refills: refills,
                copay: copay,
                weight: weight,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled float pool policy in status requested.
    static func newScheduledFloatPoolPolicy(_ code: String, label: String) -> ScheduledFloatPoolPolicy {
        return ScheduledFloatPoolPolicy(
            code: code,
            label: label,
            refills: 0,
            copay: 0.0,
            weight: 0.0,
            revision: 0,
            status: ScheduledFloatPoolPolicyStatus.requested
        )
    }
}
