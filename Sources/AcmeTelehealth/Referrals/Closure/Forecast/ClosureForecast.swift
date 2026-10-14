import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure forecast is in its life cycle.
    enum ClosureForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A closure forecast as the closure team keeps it.
    final class ClosureForecast {
        var code: String
        var title: String
        var attempts: Int
        var procedureCode: String
        var locale: String
        var ratio: Double
        var channel: String
        var updatedAt: Int
        var payer: String
        var amount: Double
        var reviewer: String
        var status: ClosureForecastStatus

        init(code: String, title: String, attempts: Int, procedureCode: String, locale: String, ratio: Double, channel: String, updatedAt: Int, payer: String, amount: Double, reviewer: String, status: ClosureForecastStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.procedureCode = procedureCode
            self.locale = locale
            self.ratio = ratio
            self.channel = channel
            self.updatedAt = updatedAt
            self.payer = payer
            self.amount = amount
            self.reviewer = reviewer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureForecastStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ClosureForecastStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(updatedAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ClosureForecast {
            return ClosureForecast(
                code: code,
                title: title,
                attempts: attempts,
                procedureCode: procedureCode,
                locale: locale,
                ratio: ratio,
                channel: channel,
                updatedAt: updatedAt,
                payer: payer,
                amount: amount,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a closure forecast in status created.
    static func newClosureForecast(_ code: String, title: String) -> ClosureForecast {
        return ClosureForecast(
            code: code,
            title: title,
            attempts: 0,
            procedureCode: "",
            locale: "",
            ratio: 0.0,
            channel: "",
            updatedAt: 0,
            payer: "",
            amount: 0.0,
            reviewer: "",
            status: ClosureForecastStatus.created
        )
    }
}
