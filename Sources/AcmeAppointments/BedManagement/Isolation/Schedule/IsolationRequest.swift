import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation request is in its life cycle.
    enum IsolationRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a isolation request and its current status.
    final class IsolationRequest {
        var code: String
        var label: String
        var version: Int
        var startsAt: Int
        var attempts: Int
        var status: IsolationRequestStatus

        init(code: String, label: String, version: Int, startsAt: Int, attempts: Int, status: IsolationRequestStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.startsAt = startsAt
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

        func canMoveTo(_ next: IsolationRequestStatus) -> Bool {
            switch status {
            case .idle:
                return next == IsolationRequestStatus.warming || next == IsolationRequestStatus.ready
            case .warming:
                return next == IsolationRequestStatus.stopped
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

        func moveTo(_ next: IsolationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("isolation request") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(version) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> IsolationRequest {
            return IsolationRequest(
                code: code,
                label: label,
                version: version,
                startsAt: startsAt,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation request in status idle.
    static func newIsolationRequest(_ code: String, label: String) -> IsolationRequest {
        return IsolationRequest(
            code: code,
            label: label,
            version: 0,
            startsAt: 0,
            attempts: 0,
            status: IsolationRequestStatus.idle
        )
    }
}
