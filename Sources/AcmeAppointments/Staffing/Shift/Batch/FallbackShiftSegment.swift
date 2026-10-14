import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback shift segment is in its life cycle.
    enum FallbackShiftSegmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback shift segment as the shift team keeps it.
    final class FallbackShiftSegment {
        var code: String
        var name: String
        var attempts: Int
        var tags: [String]
        var ratio: Double
        var status: FallbackShiftSegmentStatus

        init(code: String, name: String, attempts: Int, tags: [String], ratio: Double, status: FallbackShiftSegmentStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.tags = tags
            self.ratio = ratio
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

        func canMoveTo(_ next: FallbackShiftSegmentStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackShiftSegmentStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: FallbackShiftSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback shift segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return (ratio * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> FallbackShiftSegment {
            return FallbackShiftSegment(
                code: code,
                name: name,
                attempts: attempts,
                tags: tags,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback shift segment in status idle.
    static func newFallbackShiftSegment(_ code: String, name: String) -> FallbackShiftSegment {
        return FallbackShiftSegment(
            code: code,
            name: name,
            attempts: 0,
            tags: [],
            ratio: 0.0,
            status: FallbackShiftSegmentStatus.idle
        )
    }
}
