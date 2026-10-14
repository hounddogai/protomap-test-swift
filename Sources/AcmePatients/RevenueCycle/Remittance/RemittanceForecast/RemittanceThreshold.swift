import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance threshold is in its life cycle.
    enum RemittanceThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A remittance threshold as the remittance team keeps it.
    final class RemittanceThreshold {
        var code: String
        var title: String
        var description: String
        var timezone: String
        var currency: String
        var discount: Double
        var maximum: Double
        var status: RemittanceThresholdStatus

        init(code: String, title: String, description: String, timezone: String, currency: String, discount: Double, maximum: Double, status: RemittanceThresholdStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.timezone = timezone
            self.currency = currency
            self.discount = discount
            self.maximum = maximum
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

        func canMoveTo(_ next: RemittanceThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == RemittanceThresholdStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RemittanceThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance threshold") \(code)"
        }

        func weightedValue() -> Double {
            return ((discount - maximum) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceThreshold {
            return RemittanceThreshold(
                code: code,
                title: title,
                description: description,
                timezone: timezone,
                currency: currency,
                discount: discount,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance threshold in status new.
    static func newRemittanceThreshold(_ code: String, title: String) -> RemittanceThreshold {
        return RemittanceThreshold(
            code: code,
            title: title,
            description: "",
            timezone: "",
            currency: "",
            discount: 0.0,
            maximum: 0.0,
            status: RemittanceThresholdStatus.new
        )
    }
}
