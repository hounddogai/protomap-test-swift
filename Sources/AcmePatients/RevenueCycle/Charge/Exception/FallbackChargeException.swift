import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback charge exception is in its life cycle.
    enum FallbackChargeExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback charge exception and its current status.
    final class FallbackChargeException {
        var code: String
        var title: String
        var allergy: String
        var attempts: Int
        var floorValue: Double
        var visitMinutes: Int
        var channel: String
        var externalRef: String
        var currency: String
        var margin: Double
        var payer: String
        var status: FallbackChargeExceptionStatus

        init(code: String, title: String, allergy: String, attempts: Int, floorValue: Double, visitMinutes: Int, channel: String, externalRef: String, currency: String, margin: Double, payer: String, status: FallbackChargeExceptionStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.attempts = attempts
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.externalRef = externalRef
            self.currency = currency
            self.margin = margin
            self.payer = payer
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

        func canMoveTo(_ next: FallbackChargeExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackChargeExceptionStatus.draining || next == FallbackChargeExceptionStatus.stopped
            case .ready:
                return next == FallbackChargeExceptionStatus.stopped
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

        func moveTo(_ next: FallbackChargeExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback charge exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return (Double(visitMinutes) * margin * 100).rounded() / 100
        }

        func copyValue() -> FallbackChargeException {
            return FallbackChargeException(
                code: code,
                title: title,
                allergy: allergy,
                attempts: attempts,
                floorValue: floorValue,
                visitMinutes: visitMinutes,
                channel: channel,
                externalRef: externalRef,
                currency: currency,
                margin: margin,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a fallback charge exception in status idle.
    static func newFallbackChargeException(_ code: String, title: String) -> FallbackChargeException {
        return FallbackChargeException(
            code: code,
            title: title,
            allergy: "",
            attempts: 0,
            floorValue: 0.0,
            visitMinutes: 0,
            channel: "",
            externalRef: "",
            currency: "",
            margin: 0.0,
            payer: "",
            status: FallbackChargeExceptionStatus.idle
        )
    }
}
