import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement forecast is in its life cycle.
    enum StatementForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A statement forecast. Its code is unique within a tenant.
    final class StatementForecast {
        var code: String
        var title: String
        var retries: Int
        var amount: Double
        var margin: Double
        var contactEmail: String
        var status: StatementForecastStatus

        init(code: String, title: String, retries: Int, amount: Double, margin: Double, contactEmail: String, status: StatementForecastStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.amount = amount
            self.margin = margin
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: StatementForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == StatementForecastStatus.draining || next == StatementForecastStatus.stopped
            case .warming:
                return next == StatementForecastStatus.draining || next == StatementForecastStatus.stopped
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

        func moveTo(_ next: StatementForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return (margin * amount * 100).rounded() / 100
        }

        func copyValue() -> StatementForecast {
            return StatementForecast(
                code: code,
                title: title,
                retries: retries,
                amount: amount,
                margin: margin,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a statement forecast in status idle.
    static func newStatementForecast(_ code: String, title: String) -> StatementForecast {
        return StatementForecast(
            code: code,
            title: title,
            retries: 0,
            amount: 0.0,
            margin: 0.0,
            contactEmail: "",
            status: StatementForecastStatus.idle
        )
    }
}
