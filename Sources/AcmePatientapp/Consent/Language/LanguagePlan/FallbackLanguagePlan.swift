import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback language plan is in its life cycle.
    enum FallbackLanguagePlanStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One fallback language plan, with what the planners need to act on it.
    final class FallbackLanguagePlan {
        var code: String
        var title: String
        var minimum: Double
        var contactEmail: String
        var ratio: Double
        var status: FallbackLanguagePlanStatus

        init(code: String, title: String, minimum: Double, contactEmail: String, ratio: Double, status: FallbackLanguagePlanStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: FallbackLanguagePlanStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackLanguagePlanStatus.warming || next == FallbackLanguagePlanStatus.draining
            case .warming:
                return next == FallbackLanguagePlanStatus.stopped
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: FallbackLanguagePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback language plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((ratio + minimum) * 100).rounded() / 100
        }

        func copyValue() -> FallbackLanguagePlan {
            return FallbackLanguagePlan(
                code: code,
                title: title,
                minimum: minimum,
                contactEmail: contactEmail,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback language plan in status idle.
    static func newFallbackLanguagePlan(_ code: String, title: String) -> FallbackLanguagePlan {
        return FallbackLanguagePlan(
            code: code,
            title: title,
            minimum: 0.0,
            contactEmail: "",
            ratio: 0.0,
            status: FallbackLanguagePlanStatus.idle
        )
    }
}
