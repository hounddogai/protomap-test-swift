import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement metric is in its life cycle.
    enum StatementMetricStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a statement metric and its current status.
    final class StatementMetric {
        var code: String
        var name: String
        var ward: String
        var visitMinutes: Int
        var expiresAt: Int
        var status: StatementMetricStatus

        init(code: String, name: String, ward: String, visitMinutes: Int, expiresAt: Int, status: StatementMetricStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: StatementMetricStatus) -> Bool {
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
                return next == StatementMetricStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == StatementMetricStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("statement metric") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(visitMinutes) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> StatementMetric {
            return StatementMetric(
                code: code,
                name: name,
                ward: ward,
                visitMinutes: visitMinutes,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a statement metric in status idle.
    static func newStatementMetric(_ code: String, name: String) -> StatementMetric {
        return StatementMetric(
            code: code,
            name: name,
            ward: "",
            visitMinutes: 0,
            expiresAt: 0,
            status: StatementMetricStatus.idle
        )
    }
}
