import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy exception is in its life cycle.
    enum ProxyExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A proxy exception as the proxy team keeps it.
    final class ProxyException {
        var code: String
        var label: String
        var minimum: Double
        var archived: Bool
        var durationMinutes: Int
        var expiresAt: Int
        var copay: Double
        var priority: Int
        var attempts: Int
        var status: ProxyExceptionStatus

        init(code: String, label: String, minimum: Double, archived: Bool, durationMinutes: Int, expiresAt: Int, copay: Double, priority: Int, attempts: Int, status: ProxyExceptionStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.copay = copay
            self.priority = priority
            self.attempts = attempts
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

        func canMoveTo(_ next: ProxyExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ProxyExceptionStatus.draining || next == ProxyExceptionStatus.stopped
            case .draining:
                return next == ProxyExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedExposure() -> Double {
            return ((Double(expiresAt) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> ProxyException {
            return ProxyException(
                code: code,
                label: label,
                minimum: minimum,
                archived: archived,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                copay: copay,
                priority: priority,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a proxy exception in status idle.
    static func newProxyException(_ code: String, label: String) -> ProxyException {
        return ProxyException(
            code: code,
            label: label,
            minimum: 0.0,
            archived: false,
            durationMinutes: 0,
            expiresAt: 0,
            copay: 0.0,
            priority: 0,
            attempts: 0,
            status: ProxyExceptionStatus.idle
        )
    }
}
