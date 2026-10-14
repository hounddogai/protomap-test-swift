import AcmePlatform
import Foundation

extension Referrals {
    /// Where a strict closure segment is in its life cycle.
    enum StrictClosureSegmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One strict closure segment, with what the planners need to act on it.
    final class StrictClosureSegment {
        var code: String
        var name: String
        var maximum: Double
        var minimum: Double
        var version: Int
        var status: StrictClosureSegmentStatus

        init(code: String, name: String, maximum: Double, minimum: Double, version: Int, status: StrictClosureSegmentStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.minimum = minimum
            self.version = version
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

        func canMoveTo(_ next: StrictClosureSegmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == StrictClosureSegmentStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StrictClosureSegmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictClosureSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict closure segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveValue() -> Double {
            return (Double(version) * maximum * 100).rounded() / 100
        }

        func copyValue() -> StrictClosureSegment {
            return StrictClosureSegment(
                code: code,
                name: name,
                maximum: maximum,
                minimum: minimum,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict closure segment in status new.
    static func newStrictClosureSegment(_ code: String, name: String) -> StrictClosureSegment {
        return StrictClosureSegment(
            code: code,
            name: name,
            maximum: 0.0,
            minimum: 0.0,
            version: 0,
            status: StrictClosureSegmentStatus.new
        )
    }
}
