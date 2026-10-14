import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback network checkpoint is in its life cycle.
    enum FallbackNetworkCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback network checkpoint as the network team keeps it.
    final class FallbackNetworkCheckpoint {
        var code: String
        var label: String
        var priority: Int
        var patientRef: String
        var cost: Double
        var rate: Double
        var region: String
        var status: FallbackNetworkCheckpointStatus

        init(code: String, label: String, priority: Int, patientRef: String, cost: Double, rate: Double, region: String, status: FallbackNetworkCheckpointStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.patientRef = patientRef
            self.cost = cost
            self.rate = rate
            self.region = region
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

        func canMoveTo(_ next: FallbackNetworkCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackNetworkCheckpointStatus.ready
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackNetworkCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback network checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback network checkpoint") \(code)"
        }

        func projectedTotal() -> Double {
            return (rate * cost * 100).rounded() / 100
        }

        func copyValue() -> FallbackNetworkCheckpoint {
            return FallbackNetworkCheckpoint(
                code: code,
                label: label,
                priority: priority,
                patientRef: patientRef,
                cost: cost,
                rate: rate,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback network checkpoint in status idle.
    static func newFallbackNetworkCheckpoint(_ code: String, label: String) -> FallbackNetworkCheckpoint {
        return FallbackNetworkCheckpoint(
            code: code,
            label: label,
            priority: 0,
            patientRef: "",
            cost: 0.0,
            rate: 0.0,
            region: "",
            status: FallbackNetworkCheckpointStatus.idle
        )
    }
}
