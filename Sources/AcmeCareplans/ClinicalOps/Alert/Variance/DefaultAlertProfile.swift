import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default alert profile is in its life cycle.
    enum DefaultAlertProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default alert profile and its current status.
    final class DefaultAlertProfile {
        var code: String
        var title: String
        var margin: Double
        var maximum: Double
        var specialty: String
        var status: DefaultAlertProfileStatus

        init(code: String, title: String, margin: Double, maximum: Double, specialty: String, status: DefaultAlertProfileStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.maximum = maximum
            self.specialty = specialty
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

        func canMoveTo(_ next: DefaultAlertProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
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
                return next == DefaultAlertProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultAlertProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default alert profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default alert profile") \(code)"
        }

        func effectiveValue() -> Double {
            return ((margin + maximum) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAlertProfile {
            return DefaultAlertProfile(
                code: code,
                title: title,
                margin: margin,
                maximum: maximum,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default alert profile in status idle.
    static func newDefaultAlertProfile(_ code: String, title: String) -> DefaultAlertProfile {
        return DefaultAlertProfile(
            code: code,
            title: title,
            margin: 0.0,
            maximum: 0.0,
            specialty: "",
            status: DefaultAlertProfileStatus.idle
        )
    }
}
