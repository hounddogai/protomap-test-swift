import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched statement segment is in its life cycle.
    enum BatchedStatementSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched statement segment, with what the planners need to act on it.
    final class BatchedStatementSegment {
        var code: String
        var name: String
        var reviewer: String
        var priority: Int
        var windowDays: Int
        var acuity: Int
        var segment: String
        var status: BatchedStatementSegmentStatus

        init(code: String, name: String, reviewer: String, priority: Int, windowDays: Int, acuity: Int, segment: String, status: BatchedStatementSegmentStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.priority = priority
            self.windowDays = windowDays
            self.acuity = acuity
            self.segment = segment
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

        func canMoveTo(_ next: BatchedStatementSegmentStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedStatementSegmentStatus.revoked || next == BatchedStatementSegmentStatus.expired
            case .revoked:
                return next == BatchedStatementSegmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedStatementSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched statement segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedExposure() -> Double {
            return ((Double(acuity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedStatementSegment {
            return BatchedStatementSegment(
                code: code,
                name: name,
                reviewer: reviewer,
                priority: priority,
                windowDays: windowDays,
                acuity: acuity,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched statement segment in status requested.
    static func newBatchedStatementSegment(_ code: String, name: String) -> BatchedStatementSegment {
        return BatchedStatementSegment(
            code: code,
            name: name,
            reviewer: "",
            priority: 0,
            windowDays: 0,
            acuity: 0,
            segment: "",
            status: BatchedStatementSegmentStatus.requested
        )
    }
}
