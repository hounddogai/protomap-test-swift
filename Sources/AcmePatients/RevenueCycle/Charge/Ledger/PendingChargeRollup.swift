import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending charge rollup is in its life cycle.
    enum PendingChargeRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a pending charge rollup and its current status.
    final class PendingChargeRollup {
        var code: String
        var label: String
        var threshold: Double
        var reviewer: String
        var retries: Int
        var approved: Bool
        var status: PendingChargeRollupStatus

        init(code: String, label: String, threshold: Double, reviewer: String, retries: Int, approved: Bool, status: PendingChargeRollupStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.reviewer = reviewer
            self.retries = retries
            self.approved = approved
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

        func canMoveTo(_ next: PendingChargeRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PendingChargeRollupStatus.expired
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

        func moveTo(_ next: PendingChargeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending charge rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return (Double(retries) * threshold * 100).rounded() / 100
        }

        func copyValue() -> PendingChargeRollup {
            return PendingChargeRollup(
                code: code,
                label: label,
                threshold: threshold,
                reviewer: reviewer,
                retries: retries,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending charge rollup in status requested.
    static func newPendingChargeRollup(_ code: String, label: String) -> PendingChargeRollup {
        return PendingChargeRollup(
            code: code,
            label: label,
            threshold: 0.0,
            reviewer: "",
            retries: 0,
            approved: false,
            status: PendingChargeRollupStatus.requested
        )
    }
}
