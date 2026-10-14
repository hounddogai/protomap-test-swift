import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback credential target is in its life cycle.
    enum FallbackCredentialTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One fallback credential target, with what the planners need to act on it.
    final class FallbackCredentialTarget {
        var code: String
        var label: String
        var version: Int
        var priority: Int
        var bed: String
        var segment: String
        var pinned: Bool
        var status: FallbackCredentialTargetStatus

        init(code: String, label: String, version: Int, priority: Int, bed: String, segment: String, pinned: Bool, status: FallbackCredentialTargetStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.priority = priority
            self.bed = bed
            self.segment = segment
            self.pinned = pinned
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

        func canMoveTo(_ next: FallbackCredentialTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackCredentialTargetStatus.ready || next == FallbackCredentialTargetStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackCredentialTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackCredentialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback credential target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("fallback credential target") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(version) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCredentialTarget {
            return FallbackCredentialTarget(
                code: code,
                label: label,
                version: version,
                priority: priority,
                bed: bed,
                segment: segment,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a fallback credential target in status idle.
    static func newFallbackCredentialTarget(_ code: String, label: String) -> FallbackCredentialTarget {
        return FallbackCredentialTarget(
            code: code,
            label: label,
            version: 0,
            priority: 0,
            bed: "",
            segment: "",
            pinned: false,
            status: FallbackCredentialTargetStatus.idle
        )
    }
}
