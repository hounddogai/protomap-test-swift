import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback read baseline is in its life cycle.
    enum FallbackReadBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback read baseline and its current status.
    final class FallbackReadBaseline {
        var code: String
        var title: String
        var channel: String
        var createdAt: Int
        var reviewer: String
        var status: FallbackReadBaselineStatus

        init(code: String, title: String, channel: String, createdAt: Int, reviewer: String, status: FallbackReadBaselineStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.createdAt = createdAt
            self.reviewer = reviewer
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

        func canMoveTo(_ next: FallbackReadBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackReadBaselineStatus.ready
            case .warming:
                return next == FallbackReadBaselineStatus.ready || next == FallbackReadBaselineStatus.draining
            case .ready:
                return next == FallbackReadBaselineStatus.stopped
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

        func moveTo(_ next: FallbackReadBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback read baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> FallbackReadBaseline {
            return FallbackReadBaseline(
                code: code,
                title: title,
                channel: channel,
                createdAt: createdAt,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback read baseline in status idle.
    static func newFallbackReadBaseline(_ code: String, title: String) -> FallbackReadBaseline {
        return FallbackReadBaseline(
            code: code,
            title: title,
            channel: "",
            createdAt: 0,
            reviewer: "",
            status: FallbackReadBaselineStatus.idle
        )
    }
}
