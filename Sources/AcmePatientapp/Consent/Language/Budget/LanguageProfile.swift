import AcmePlatform
import Foundation

extension Consent {
    /// Where a language profile is in its life cycle.
    enum LanguageProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a language profile and its current status.
    final class LanguageProfile {
        var code: String
        var name: String
        var minimum: Double
        var bed: String
        var title: String
        var status: LanguageProfileStatus

        init(code: String, name: String, minimum: Double, bed: String, title: String, status: LanguageProfileStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.bed = bed
            self.title = title
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

        func canMoveTo(_ next: LanguageProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LanguageProfileStatus.ready || next == LanguageProfileStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LanguageProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> LanguageProfile {
            return LanguageProfile(code: code, name: name, minimum: minimum, bed: bed, title: title, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a language profile in status idle.
    static func newLanguageProfile(_ code: String, name: String) -> LanguageProfile {
        return LanguageProfile(
            code: code,
            name: name,
            minimum: 0.0,
            bed: "",
            title: "",
            status: LanguageProfileStatus.idle
        )
    }
}
