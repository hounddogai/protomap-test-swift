import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement notice is in its life cycle.
    enum StatementNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One statement notice, with what the planners need to act on it.
    final class StatementNotice {
        var code: String
        var name: String
        var discount: Double
        var channel: String
        var limit: Int
        var ceiling: Double
        var status: StatementNoticeStatus

        init(code: String, name: String, discount: Double, channel: String, limit: Int, ceiling: Double, status: StatementNoticeStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.channel = channel
            self.limit = limit
            self.ceiling = ceiling
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

        func canMoveTo(_ next: StatementNoticeStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StatementNoticeStatus.draining || next == StatementNoticeStatus.stopped
            case .draining:
                return next == StatementNoticeStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedLoad() -> Double {
            return ((ceiling - discount) * 100).rounded() / 100
        }

        func copyValue() -> StatementNotice {
            return StatementNotice(
                code: code,
                name: name,
                discount: discount,
                channel: channel,
                limit: limit,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a statement notice in status idle.
    static func newStatementNotice(_ code: String, name: String) -> StatementNotice {
        return StatementNotice(
            code: code,
            name: name,
            discount: 0.0,
            channel: "",
            limit: 0,
            ceiling: 0.0,
            status: StatementNoticeStatus.idle
        )
    }
}
