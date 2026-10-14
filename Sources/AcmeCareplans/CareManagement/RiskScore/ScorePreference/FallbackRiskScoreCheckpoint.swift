import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback risk score checkpoint is in its life cycle.
    enum FallbackRiskScoreCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback risk score checkpoint as the risk score team keeps it.
    final class FallbackRiskScoreCheckpoint {
        var code: String
        var title: String
        var windowDays: Int
        var pinned: Bool
        var channel: String
        var visible: Bool
        var status: FallbackRiskScoreCheckpointStatus

        init(code: String, title: String, windowDays: Int, pinned: Bool, channel: String, visible: Bool, status: FallbackRiskScoreCheckpointStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.pinned = pinned
            self.channel = channel
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackRiskScoreCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackRiskScoreCheckpointStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == FallbackRiskScoreCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRiskScoreCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback risk score checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> FallbackRiskScoreCheckpoint {
            return FallbackRiskScoreCheckpoint(
                code: code,
                title: title,
                windowDays: windowDays,
                pinned: pinned,
                channel: channel,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback risk score checkpoint in status open.
    static func newFallbackRiskScoreCheckpoint(_ code: String, title: String) -> FallbackRiskScoreCheckpoint {
        return FallbackRiskScoreCheckpoint(
            code: code,
            title: title,
            windowDays: 0,
            pinned: false,
            channel: "",
            visible: false,
            status: FallbackRiskScoreCheckpointStatus.`open`
        )
    }
}
