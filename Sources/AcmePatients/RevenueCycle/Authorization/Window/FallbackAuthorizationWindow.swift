import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback authorization window is in its life cycle.
    enum FallbackAuthorizationWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback authorization window, with what the planners need to act on it.
    final class FallbackAuthorizationWindow {
        var code: String
        var name: String
        var specialty: String
        var version: Int
        var bed: String
        var currency: String
        var status: FallbackAuthorizationWindowStatus

        init(code: String, name: String, specialty: String, version: Int, bed: String, currency: String, status: FallbackAuthorizationWindowStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.version = version
            self.bed = bed
            self.currency = currency
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

        func canMoveTo(_ next: FallbackAuthorizationWindowStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FallbackAuthorizationWindowStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: FallbackAuthorizationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback authorization window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("fallback authorization window") \(code)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> FallbackAuthorizationWindow {
            return FallbackAuthorizationWindow(
                code: code,
                name: name,
                specialty: specialty,
                version: version,
                bed: bed,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback authorization window in status planned.
    static func newFallbackAuthorizationWindow(_ code: String, name: String) -> FallbackAuthorizationWindow {
        return FallbackAuthorizationWindow(
            code: code,
            name: name,
            specialty: "",
            version: 0,
            bed: "",
            currency: "",
            status: FallbackAuthorizationWindowStatus.planned
        )
    }
}
