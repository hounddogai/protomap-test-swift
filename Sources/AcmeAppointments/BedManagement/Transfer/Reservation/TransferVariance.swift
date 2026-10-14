import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer variance is in its life cycle.
    enum TransferVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a transfer variance and its current status.
    final class TransferVariance {
        var code: String
        var title: String
        var locale: String
        var active: Bool
        var attempts: Int
        var discount: Double
        var status: TransferVarianceStatus

        init(code: String, title: String, locale: String, active: Bool, attempts: Int, discount: Double, status: TransferVarianceStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.active = active
            self.attempts = attempts
            self.discount = discount
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

        func canMoveTo(_ next: TransferVarianceStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: TransferVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("transfer variance") \(code)"
        }

        func effectiveValue() -> Double {
            return ((discount + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TransferVariance {
            return TransferVariance(
                code: code,
                title: title,
                locale: locale,
                active: active,
                attempts: attempts,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a transfer variance in status new.
    static func newTransferVariance(_ code: String, title: String) -> TransferVariance {
        return TransferVariance(
            code: code,
            title: title,
            locale: "",
            active: false,
            attempts: 0,
            discount: 0.0,
            status: TransferVarianceStatus.new
        )
    }
}
