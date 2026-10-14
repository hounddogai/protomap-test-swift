import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive remittance snapshot is in its life cycle.
    enum AdaptiveRemittanceSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a adaptive remittance snapshot and its current status.
    final class AdaptiveRemittanceSnapshot {
        var code: String
        var name: String
        var reviewer: String
        var threshold: Double
        var durationMinutes: Int
        var approved: Bool
        var updatedAt: Int
        var status: AdaptiveRemittanceSnapshotStatus

        init(code: String, name: String, reviewer: String, threshold: Double, durationMinutes: Int, approved: Bool, updatedAt: Int, status: AdaptiveRemittanceSnapshotStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRemittanceSnapshotStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AdaptiveRemittanceSnapshotStatus.running || next == AdaptiveRemittanceSnapshotStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == AdaptiveRemittanceSnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRemittanceSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive remittance snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return (threshold * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRemittanceSnapshot {
            return AdaptiveRemittanceSnapshot(
                code: code,
                name: name,
                reviewer: reviewer,
                threshold: threshold,
                durationMinutes: durationMinutes,
                approved: approved,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive remittance snapshot in status new.
    static func newAdaptiveRemittanceSnapshot(_ code: String, name: String) -> AdaptiveRemittanceSnapshot {
        return AdaptiveRemittanceSnapshot(
            code: code,
            name: name,
            reviewer: "",
            threshold: 0.0,
            durationMinutes: 0,
            approved: false,
            updatedAt: 0,
            status: AdaptiveRemittanceSnapshotStatus.new
        )
    }
}
