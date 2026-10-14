import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling revocation bundle is in its life cycle.
    enum RollingRevocationBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rolling revocation bundle, with what the planners need to act on it.
    final class RollingRevocationBundle {
        var code: String
        var title: String
        var margin: Double
        var cost: Double
        var name: String
        var status: RollingRevocationBundleStatus

        init(code: String, title: String, margin: Double, cost: Double, name: String, status: RollingRevocationBundleStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.cost = cost
            self.name = name
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

        func canMoveTo(_ next: RollingRevocationBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RollingRevocationBundleStatus.ready || next == RollingRevocationBundleStatus.stopped
            case .ready:
                return next == RollingRevocationBundleStatus.draining || next == RollingRevocationBundleStatus.stopped
            case .draining:
                return next == RollingRevocationBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingRevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling revocation bundle") \(code)"
        }

        func netVolume() -> Double {
            return ((cost + margin) * 100).rounded() / 100
        }

        func copyValue() -> RollingRevocationBundle {
            return RollingRevocationBundle(
                code: code,
                title: title,
                margin: margin,
                cost: cost,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling revocation bundle in status idle.
    static func newRollingRevocationBundle(_ code: String, title: String) -> RollingRevocationBundle {
        return RollingRevocationBundle(
            code: code,
            title: title,
            margin: 0.0,
            cost: 0.0,
            name: "",
            status: RollingRevocationBundleStatus.idle
        )
    }
}
