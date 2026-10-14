import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default care protocol audit is in its life cycle.
    enum DefaultCareProtocolAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a default care protocol audit and its current status.
    final class DefaultCareProtocolAudit {
        var code: String
        var title: String
        var maximum: Double
        var visitMinutes: Int
        var ratio: Double
        var status: DefaultCareProtocolAuditStatus

        init(code: String, title: String, maximum: Double, visitMinutes: Int, ratio: Double, status: DefaultCareProtocolAuditStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: DefaultCareProtocolAuditStatus) -> Bool {
            switch status {
            case .idle:
                return next == DefaultCareProtocolAuditStatus.warming || next == DefaultCareProtocolAuditStatus.stopped
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
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultCareProtocolAuditStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default care protocol audit") \(code)"
        }

        func netExposure() -> Double {
            return (Double(visitMinutes) * ratio * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolAudit {
            return DefaultCareProtocolAudit(
                code: code,
                title: title,
                maximum: maximum,
                visitMinutes: visitMinutes,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default care protocol audit in status idle.
    static func newDefaultCareProtocolAudit(_ code: String, title: String) -> DefaultCareProtocolAudit {
        return DefaultCareProtocolAudit(
            code: code,
            title: title,
            maximum: 0.0,
            visitMinutes: 0,
            ratio: 0.0,
            status: DefaultCareProtocolAuditStatus.idle
        )
    }
}
