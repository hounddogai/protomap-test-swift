import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive denial checkpoint is in its life cycle.
    enum AdaptiveDenialCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive denial checkpoint, with what the planners need to act on it.
    final class AdaptiveDenialCheckpoint {
        var code: String
        var label: String
        var endsAt: Int
        var batchSize: Int
        var unit: String
        var status: AdaptiveDenialCheckpointStatus

        init(code: String, label: String, endsAt: Int, batchSize: Int, unit: String, status: AdaptiveDenialCheckpointStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.unit = unit
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

        func canMoveTo(_ next: AdaptiveDenialCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveDenialCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveDenialCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive denial checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(endsAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveDenialCheckpoint {
            return AdaptiveDenialCheckpoint(
                code: code,
                label: label,
                endsAt: endsAt,
                batchSize: batchSize,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive denial checkpoint in status proposed.
    static func newAdaptiveDenialCheckpoint(_ code: String, label: String) -> AdaptiveDenialCheckpoint {
        return AdaptiveDenialCheckpoint(
            code: code,
            label: label,
            endsAt: 0,
            batchSize: 0,
            unit: "",
            status: AdaptiveDenialCheckpointStatus.proposed
        )
    }
}
