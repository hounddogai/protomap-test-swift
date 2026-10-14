import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled denial claim is in its life cycle.
    enum ScheduledDenialClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a scheduled denial claim and its current status.
    final class ScheduledDenialClaim {
        var code: String
        var name: String
        var threshold: Double
        var active: Bool
        var bed: String
        var status: ScheduledDenialClaimStatus

        init(code: String, name: String, threshold: Double, active: Bool, bed: String, status: ScheduledDenialClaimStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.active = active
            self.bed = bed
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

        func canMoveTo(_ next: ScheduledDenialClaimStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledDenialClaimStatus.rejected || next == ScheduledDenialClaimStatus.withdrawn
            case .rejected:
                return next == ScheduledDenialClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledDenialClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled denial claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled denial claim") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> ScheduledDenialClaim {
            return ScheduledDenialClaim(
                code: code,
                name: name,
                threshold: threshold,
                active: active,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled denial claim in status proposed.
    static func newScheduledDenialClaim(_ code: String, name: String) -> ScheduledDenialClaim {
        return ScheduledDenialClaim(
            code: code,
            name: name,
            threshold: 0.0,
            active: false,
            bed: "",
            status: ScheduledDenialClaimStatus.proposed
        )
    }
}
