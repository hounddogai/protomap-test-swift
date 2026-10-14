import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive panel snapshot is in its life cycle.
    enum AdaptivePanelSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive panel snapshot and its current status.
    final class AdaptivePanelSnapshot {
        var code: String
        var label: String
        var channel: String
        var ratio: Double
        var updatedAt: Int
        var budget: Double
        var maximum: Double
        var checksum: String
        var ceiling: Double
        var retries: Int
        var status: AdaptivePanelSnapshotStatus

        init(code: String, label: String, channel: String, ratio: Double, updatedAt: Int, budget: Double, maximum: Double, checksum: String, ceiling: Double, retries: Int, status: AdaptivePanelSnapshotStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.budget = budget
            self.maximum = maximum
            self.checksum = checksum
            self.ceiling = ceiling
            self.retries = retries
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

        func canMoveTo(_ next: AdaptivePanelSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptivePanelSnapshotStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptivePanelSnapshotStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePanelSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive panel snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("adaptive panel snapshot") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(updatedAt) * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePanelSnapshot {
            return AdaptivePanelSnapshot(
                code: code,
                label: label,
                channel: channel,
                ratio: ratio,
                updatedAt: updatedAt,
                budget: budget,
                maximum: maximum,
                checksum: checksum,
                ceiling: ceiling,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive panel snapshot in status proposed.
    static func newAdaptivePanelSnapshot(_ code: String, label: String) -> AdaptivePanelSnapshot {
        return AdaptivePanelSnapshot(
            code: code,
            label: label,
            channel: "",
            ratio: 0.0,
            updatedAt: 0,
            budget: 0.0,
            maximum: 0.0,
            checksum: "",
            ceiling: 0.0,
            retries: 0,
            status: AdaptivePanelSnapshotStatus.proposed
        )
    }
}
