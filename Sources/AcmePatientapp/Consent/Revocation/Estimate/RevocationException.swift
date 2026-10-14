import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation exception is in its life cycle.
    enum RevocationExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One revocation exception, with what the planners need to act on it.
    final class RevocationException {
        var code: String
        var name: String
        var specialty: String
        var minimum: Double
        var channel: String
        var status: RevocationExceptionStatus

        init(code: String, name: String, specialty: String, minimum: Double, channel: String, status: RevocationExceptionStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.minimum = minimum
            self.channel = channel
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

        func canMoveTo(_ next: RevocationExceptionStatus) -> Bool {
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
                case .ready:
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

        func moveTo(_ next: RevocationExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> RevocationException {
            return RevocationException(
                code: code,
                name: name,
                specialty: specialty,
                minimum: minimum,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a revocation exception in status idle.
    static func newRevocationException(_ code: String, name: String) -> RevocationException {
        return RevocationException(
            code: code,
            name: name,
            specialty: "",
            minimum: 0.0,
            channel: "",
            status: RevocationExceptionStatus.idle
        )
    }
}
