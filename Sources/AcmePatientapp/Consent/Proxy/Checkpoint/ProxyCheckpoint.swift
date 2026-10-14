import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy checkpoint is in its life cycle.
    enum ProxyCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One proxy checkpoint, with what the planners need to act on it.
    final class ProxyCheckpoint {
        var code: String
        var title: String
        var amount: Double
        var locale: String
        var ratio: Double
        var sequence: Int
        var cost: Double
        var currency: String
        var timezone: String
        var allergy: String
        var status: ProxyCheckpointStatus

        init(code: String, title: String, amount: Double, locale: String, ratio: Double, sequence: Int, cost: Double, currency: String, timezone: String, allergy: String, status: ProxyCheckpointStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.locale = locale
            self.ratio = ratio
            self.sequence = sequence
            self.cost = cost
            self.currency = currency
            self.timezone = timezone
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == ProxyCheckpointStatus.queued
            case .queued:
                return next == ProxyCheckpointStatus.failed
            case .running:
                return next == ProxyCheckpointStatus.failed
            case .done:
                return next == ProxyCheckpointStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("proxy checkpoint") \(code)"
        }

        func netValue() -> Double {
            return (amount * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> ProxyCheckpoint {
            return ProxyCheckpoint(
                code: code,
                title: title,
                amount: amount,
                locale: locale,
                ratio: ratio,
                sequence: sequence,
                cost: cost,
                currency: currency,
                timezone: timezone,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a proxy checkpoint in status new.
    static func newProxyCheckpoint(_ code: String, title: String) -> ProxyCheckpoint {
        return ProxyCheckpoint(
            code: code,
            title: title,
            amount: 0.0,
            locale: "",
            ratio: 0.0,
            sequence: 0,
            cost: 0.0,
            currency: "",
            timezone: "",
            allergy: "",
            status: ProxyCheckpointStatus.new
        )
    }
}
