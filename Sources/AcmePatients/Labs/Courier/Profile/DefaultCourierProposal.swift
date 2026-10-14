import AcmePlatform
import Foundation

extension Labs {
    /// Where a default courier proposal is in its life cycle.
    enum DefaultCourierProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One default courier proposal, with what the planners need to act on it.
    final class DefaultCourierProposal {
        var code: String
        var name: String
        var expiresAt: Int
        var rate: Double
        var source: String
        var status: DefaultCourierProposalStatus

        init(code: String, name: String, expiresAt: Int, rate: Double, source: String, status: DefaultCourierProposalStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.rate = rate
            self.source = source
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

        func canMoveTo(_ next: DefaultCourierProposalStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultCourierProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCourierProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default courier proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return (Double(expiresAt) * rate * 100).rounded() / 100
        }

        func copyValue() -> DefaultCourierProposal {
            return DefaultCourierProposal(
                code: code,
                name: name,
                expiresAt: expiresAt,
                rate: rate,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default courier proposal in status idle.
    static func newDefaultCourierProposal(_ code: String, name: String) -> DefaultCourierProposal {
        return DefaultCourierProposal(
            code: code,
            name: name,
            expiresAt: 0,
            rate: 0.0,
            source: "",
            status: DefaultCourierProposalStatus.idle
        )
    }
}
