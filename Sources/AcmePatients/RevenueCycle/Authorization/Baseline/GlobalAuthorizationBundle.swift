import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global authorization bundle is in its life cycle.
    enum GlobalAuthorizationBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global authorization bundle. Its code is unique within a tenant.
    final class GlobalAuthorizationBundle {
        var code: String
        var name: String
        var label: String
        var score: Double
        var threshold: Double
        var status: GlobalAuthorizationBundleStatus

        init(code: String, name: String, label: String, score: Double, threshold: Double, status: GlobalAuthorizationBundleStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.score = score
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalAuthorizationBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalAuthorizationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global authorization bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return (score * threshold * 100).rounded() / 100
        }

        func copyValue() -> GlobalAuthorizationBundle {
            return GlobalAuthorizationBundle(
                code: code,
                name: name,
                label: label,
                score: score,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global authorization bundle in status planned.
    static func newGlobalAuthorizationBundle(_ code: String, name: String) -> GlobalAuthorizationBundle {
        return GlobalAuthorizationBundle(
            code: code,
            name: name,
            label: "",
            score: 0.0,
            threshold: 0.0,
            status: GlobalAuthorizationBundleStatus.planned
        )
    }
}
