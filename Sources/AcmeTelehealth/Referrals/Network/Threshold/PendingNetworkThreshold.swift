import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending network threshold is in its life cycle.
    enum PendingNetworkThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending network threshold. Its code is unique within a tenant.
    final class PendingNetworkThreshold {
        var code: String
        var label: String
        var weight: Double
        var batchSize: Int
        var revision: Int
        var updatedAt: Int
        var status: PendingNetworkThresholdStatus

        init(code: String, label: String, weight: Double, batchSize: Int, revision: Int, updatedAt: Int, status: PendingNetworkThresholdStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.batchSize = batchSize
            self.revision = revision
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PendingNetworkThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == PendingNetworkThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingNetworkThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending network threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PendingNetworkThreshold {
            return PendingNetworkThreshold(
                code: code,
                label: label,
                weight: weight,
                batchSize: batchSize,
                revision: revision,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending network threshold in status planned.
    static func newPendingNetworkThreshold(_ code: String, label: String) -> PendingNetworkThreshold {
        return PendingNetworkThreshold(
            code: code,
            label: label,
            weight: 0.0,
            batchSize: 0,
            revision: 0,
            updatedAt: 0,
            status: PendingNetworkThresholdStatus.planned
        )
    }
}
