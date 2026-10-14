import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive risk score checkpoint is in its life cycle.
    enum AdaptiveRiskScoreCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive risk score checkpoint and its current status.
    final class AdaptiveRiskScoreCheckpoint {
        var code: String
        var name: String
        var copay: Double
        var graceDays: Int
        var batchSize: Int
        var ceiling: Double
        var status: AdaptiveRiskScoreCheckpointStatus

        init(code: String, name: String, copay: Double, graceDays: Int, batchSize: Int, ceiling: Double, status: AdaptiveRiskScoreCheckpointStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.ceiling = ceiling
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

        func canMoveTo(_ next: AdaptiveRiskScoreCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AdaptiveRiskScoreCheckpointStatus.rejected || next == AdaptiveRiskScoreCheckpointStatus.withdrawn
            case .rejected:
                return next == AdaptiveRiskScoreCheckpointStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRiskScoreCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive risk score checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive risk score checkpoint") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((copay + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRiskScoreCheckpoint {
            return AdaptiveRiskScoreCheckpoint(
                code: code,
                name: name,
                copay: copay,
                graceDays: graceDays,
                batchSize: batchSize,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive risk score checkpoint in status proposed.
    static func newAdaptiveRiskScoreCheckpoint(_ code: String, name: String) -> AdaptiveRiskScoreCheckpoint {
        return AdaptiveRiskScoreCheckpoint(
            code: code,
            name: name,
            copay: 0.0,
            graceDays: 0,
            batchSize: 0,
            ceiling: 0.0,
            status: AdaptiveRiskScoreCheckpointStatus.proposed
        )
    }
}
